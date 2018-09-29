struct StackBuffer
  def initialize(@buffer : UInt8*)
    @pos = 0
    @buffer[@pos] = 0_u8
  end

  @[AlwaysInline]
  def write(slice : Bytes) : Int32
    count = slice.size

    return cur_pos if count == 0

    slice.copy_to(@buffer + @pos, count)
    @pos += count
    @buffer[@pos] = 0_u8
    cur_pos
  end

  @[AlwaysInline]
  def <<(obj : String) : Int32
    write(obj.to_slice)
  end

  @[AlwaysInline]
  def <<(obj : Char) : Int32
    @buffer[@pos] = obj
    @pos += obj.bytesize
    cur_pos
  end

  @[AlwaysInline]
  def <<(obj : Number) : Int32
    write(obj.to_s.to_slice)
  end

  @[AlwaysInline]
  def <<(obj : Bool) : Int32
    write(obj.to_s.to_slice)
  end

  @[AlwaysInline]
  def to_unsafe
    @buffer
  end

  @[AlwaysInline]
  def cur_pos
    @pos + 1
  end

  @[AlwaysInline]
  def write_byte(byte : UInt8, count : Int32) : Int32
    Intrinsics.memset((@buffer + @pos), byte, count, 0_u32, false)
    @pos += count
    cur_pos
  end
end
