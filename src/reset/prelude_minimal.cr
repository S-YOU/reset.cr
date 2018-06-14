require "lib_c"
# require "signal"
require "gc"
require "intrinsics"
# require "comparable"

require "c/string"
require "c/stdlib"

abstract class IO
  def <<(obj) : self
    obj.to_s self
    self
  end
end

require "./string_minimal"
require "./string_builder"

alias Bytes = Slice(UInt8)

struct Pointer(T)
  # include Comparable(self)

  def +(other : Int)
    self + other.to_i64
  end

  def -(other : Int)
    self + (-other)
  end

  def [](offset)
    (self + offset).value
  end

  def []=(offset, value : T)
    (self + offset).value = value
  end

  def self.null
    new 0_u64
  end

  def memcmp(other : Pointer(T), count : Int)
    LibC.memcmp(self.as(Void*), (other.as(Void*)), (count * sizeof(T)))
  end

  def copy_from(source : Pointer(T), count : Int)
    source.copy_to(self, count)
  end

  def copy_to(target : Pointer, count : Int)
    target.copy_from_impl(self, count)
  end

  protected def copy_from_impl(source : Pointer(T), count : Int)
    raise ArgumentError.new("Negative count") if count < 0

    # if self.class == source.class
    Intrinsics.memcpy(self.as(Void*), source.as(Void*), bytesize(count), 0_u32, false)
    # else
    #   while (count -= 1) >= 0
    #     self[count] = source[count]
    #   end
    # end
    self
  end

  def clear(count = 1)
    Intrinsics.memset(self.as(Void*), 0_u8, bytesize(count), 0_u32, false)
  end

  private def bytesize(count)
    {% if flag?(:bits64) %}
      count.to_u64 * sizeof(T)
    {% else %}
      if count > UInt32::MAX
        raise ArgumentError.new("Given count is bigger than UInt32::MAX")
      end

      count.to_u32 * sizeof(T)
    {% end %}
  end
end

struct StaticArray(T, N)
  @[AlwaysInline]
  def to_unsafe : Pointer(T)
    pointerof(@buffer)
  end
end

module Crystal
  DPDK_PATCHED = true
end

lib LibCrystalMain
  @[Raises]
  fun __crystal_main(argc : Int32, argv : UInt8**)
end

class Object
  macro forward_missing_to(delegate)
    macro method_missing(call)
      {{delegate}}.\{{call}}
    end
  end

  def unsafe_as(type : T.class) forall T
    x = self
    pointerof(x).as(T*).value
  end
end

class String
  def to_unsafe : UInt8*
    pointerof(@c)
  end

  def to_slice : Bytes
    Slice.new(to_unsafe, bytesize, read_only: true)
  end

  def to_s
    self
  end

  def to_s(io)
    io.write_utf8(to_slice)
  end

  def starts_with?(str : String)
    return false if str.bytesize > bytesize
    to_unsafe.memcmp(str.to_unsafe, str.bytesize) == 0
  end

  def size
    @bytesize
  end
end

struct Slice(T)
  @size : Int32

  def size
    @size
  end

  def initialize(@pointer : Pointer(T), size : Int, *, @read_only = false)
    @size = size.to_i32
  end

  def copy_to(target : Pointer(T), count)
    pointer(count).copy_to(target, count)
  end
end

struct Int32
  def self.new(value)
    value.to_i32
  end

  def -
    0 - self
  end
end

struct UInt32
  MIN =          0_u32
  MAX = 4294967295_u32

  def self.new(value)
    value.to_u32
  end

  def -
    0_u32 - self
  end

  def abs
    self
  end
end

struct UInt64
  MIN =                    0_u64
  MAX = 18446744073709551615_u64

  # Returns an `UInt64` by invoking `to_u64` on *value*.
  def self.new(value)
    value.to_u64
  end
end

struct Int
  def >>(count : Int)
    if count < 0
      self << count.abs
    elsif count < sizeof(self) * 8
      self.unsafe_shr(count)
    else
      self.class.zero
    end
  end

  def <<(count : Int)
    if count < 0
      self >> count.abs
    elsif count < sizeof(self) * 8
      self.unsafe_shl(count)
    else
      self.class.zero
    end
  end

  def ===(char : Char)
    self === char.ord
  end

  def abs
    self >= 0 ? self : -self
  end

  def tdiv(other : Int)
    check_div_argument other

    unsafe_div other
  end

  private def check_div_argument(other)
    if other == 0
      raise "DivisionByZero"
    end

    {% begin %}
      if self < 0 && self == {{@type}}::MIN && other == -1
        raise "ArgumentError: Overflow: {{@type}}::MIN / -1"
      end
    {% end %}
  end

  private DIGITS_DOWNCASE = "0123456789abcdefghijklmnopqrstuvwxyz"
  private DIGITS_UPCASE   = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  private DIGITS_BASE62   = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

  def to_s
    to_s(10)
  end

  def to_s(io : IO)
    to_s(10, io)
  end

  def to_s(base : Int, upcase : Bool = false)
    raise "Invalid base" unless 2 <= base <= 36 || base == 62
    raise "upcase must be false for base 62" if upcase && base == 62

    # case self
    # when 0
    #   return "0"
    # when 1
    #   return "1"
    # end

    internal_to_s(base, upcase) do |ptr, count|
      String.new(ptr, count, count)
    end
  end

  def to_s(base : Int, io : IO, upcase : Bool = false)
    raise "Invalid base" unless 2 <= base <= 36 || base == 62
    raise "upcase must be false for base 62" if upcase && base == 62

    # case self
    # when 0
    #   io << '0'
    #   return
    # when 1
    #   io << '1'
    #   return
    # end

    internal_to_s(base, upcase) do |ptr, count|
      io.write_utf8 Slice.new(ptr, count)
    end
  end

  private def internal_to_s(base, upcase = false)
    # Given sizeof(self) <= 128 bits, we need at most 128 bytes for a base 2
    # representation, plus one byte for the trailing 0.
    chars = uninitialized UInt8[129]
    ptr_end = chars.to_unsafe + 128
    ptr = ptr_end
    num = self

    neg = num < 0

    digits = (base == 62 ? DIGITS_BASE62 : (upcase ? DIGITS_UPCASE : DIGITS_DOWNCASE)).to_unsafe

    while num != 0
      ptr -= 1
      ptr.value = digits[num.remainder(base).abs]
      num = num.tdiv(base)
    end

    if neg
      ptr -= 1
      ptr.value = '-'.ord.to_u8
    end

    count = (ptr_end - ptr).to_i32
    yield ptr, count
  end
end

struct Number
  def abs
    self < 0 ? -self : self
  end

  def self.zero : self
    new(0)
  end
end

module Math
  extend self

  def pw2ceil(v)
    # Taken from http://graphics.stanford.edu/~seander/bithacks.html#RoundUpPowerOf2
    v -= 1
    v |= v >> 1
    v |= v >> 2
    v |= v >> 4
    v |= v >> 8
    v |= v >> 16
    v += 1
  end
end
