# memcpy, non-overlap
macro memcpy(dst, src, len)
  Intrinsics.memcpy({{dst}}, {{src}}, {{len}}, 0_u32, false)
end

# memmove, can overlap
macro memmove(dst, src, len)
  Intrinsics.memmove({{dst}}, {{src}}, {{len}}, 0_u32, false)
end

# memset
macro memset(dst, val, len)
  Intrinsics.memset({{dst}}, {{val}}, {{len}}, 0_u32, false)
end

macro ipv4(a, b, c, d)
  {{((d << 24) + (c << 16) + (b << 8) + a)}}_u32
end

macro ipv4x(a, b, c, d)
  {{((d << 24) + (c << 16) + (b << 8) + a)}}.to_u32
end

macro b16(x)
  {{(((x >> 8) & 0x00FF) | ((x << 8) & 0xFF00))}}_u16
end

macro b32(x)
  {{(((x >> 24) & 0x000000FF) | ((x >> 8) & 0x0000FF00) | ((x << 8) & 0x00FF0000) | ((x << 24) & 0xFF000000))}}_u32
end
