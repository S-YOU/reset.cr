class String
  # :nodoc:
  TYPE_ID = "".crystal_type_id

  HEADER_SIZE = sizeof({Int32, Int32, Int32})

  def self.new(slice : Bytes)
    new(slice.pointer(slice.size), slice.size)
  end

  # Creates a new `String` from the given *bytes*, which are encoded in the given *encoding*.
  #
  # The *invalid* argument can be:
  # * `nil`: an exception is raised on invalid byte sequences
  # * `:skip`: invalid byte sequences are ignored
  #
  # ```
  # slice = Slice.new(2, 0_u8)
  # slice[0] = 186_u8
  # slice[1] = 195_u8
  # String.new(slice, "GB2312") # => "好"
  # ```
  def self.new(bytes : Bytes, encoding : String, invalid : Symbol? = nil) : String
    String.build do |str|
      String.encode(bytes, encoding, "UTF-8", str, invalid)
    end
  end

  # Creates a `String` from a pointer. `Bytes` will be copied from the pointer.
  #
  # This method is **unsafe**: the pointer must point to data that eventually
  # contains a zero byte that indicates the ends of the string. Otherwise,
  # the result of this method is undefined and might cause a segmentation fault.
  #
  # This method is typically used in C bindings, where you get a `char*` from a
  # library and the library guarantees that this pointer eventually has an
  # ending zero byte.
  #
  # ```
  # ptr = Pointer.malloc(5) { |i| i == 4 ? 0_u8 : ('a'.ord + i).to_u8 }
  # String.new(ptr) # => "abcd"
  # ```
  def self.new(chars : UInt8*)
    new(chars, LibC.strlen(chars))
  end

  # Creates a new `String` from a pointer, indicating its bytesize count
  # and, optionally, the UTF-8 codepoints count (size). `Bytes` will be
  # copied from the pointer.
  #
  # If the given size is zero, the amount of UTF-8 codepoints will be
  # lazily computed when needed.
  #
  # ```
  # ptr = Pointer.malloc(4) { |i| ('a'.ord + i).to_u8 }
  # String.new(ptr, 2) # => "ab"
  # ```
  def self.new(chars : UInt8*, bytesize, size = 0)
    # Avoid allocating memory for the empty string
    return "" if bytesize == 0

    new(bytesize) do |buffer|
      buffer.copy_from(chars, bytesize)
      {bytesize, size}
    end
  end

  # Creates a new `String` by allocating a buffer (`Pointer(UInt8)`) with the given capacity, then
  # yielding that buffer. The block must return a tuple with the bytesize and size
  # (UTF-8 codepoints count) of the String. If the returned size is zero, the UTF-8 codepoints
  # count will be lazily computed.
  #
  # The bytesize returned by the block must be less than or equal to the
  # capacity given to this String, otherwise `ArgumentError` is raised.
  #
  # If you need to build a `String` where the maximum capacity is unknown, use `String#build`.
  #
  # ```
  # str = String.new(4) do |buffer|
  #   buffer[0] = 'a'.ord.to_u8
  #   buffer[1] = 'b'.ord.to_u8
  #   {2, 2}
  # end
  # str # => "ab"
  # ```
  def self.new(capacity : Int)
    check_capacity_in_bounds(capacity)

    str = GC.malloc_atomic(capacity.to_u32 + HEADER_SIZE + 1).as(UInt8*)
    buffer = str.as(String).to_unsafe
    bytesize, size = yield buffer

    unless 0 <= bytesize <= capacity
      raise ArgumentError.new("Bytesize out of capacity bounds")
    end

    buffer[bytesize] = 0_u8

    # Try to reclaim some memory if capacity is bigger than what was requested
    if bytesize < capacity
      str = str.realloc(bytesize.to_u32 + HEADER_SIZE + 1)
    end

    str_header = str.as({Int32, Int32, Int32}*)
    str_header.value = {TYPE_ID, bytesize.to_i, size.to_i}
    str.as(String)
  end

  # Builds a `String` by creating a `String::Builder` with the given initial capacity, yielding
  # it to the block and finally getting a `String` out of it. The `String::Builder` automatically
  # resizes as needed.
  #
  # ```
  # str = String.build do |str|
  #   str << "hello "
  #   str << 1
  # end
  # str # => "hello 1"
  # ```
  def self.build(capacity = 64) : self
    String::Builder.build(capacity) do |builder|
      yield builder
    end
  end

  # Returns the number of bytes in this string.
  #
  # ```
  # "hello".bytesize # => 5
  # "你好".bytesize    # => 6
  # ```
  def bytesize
    @bytesize
  end
end
