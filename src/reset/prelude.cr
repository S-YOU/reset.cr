# Entries to this file should only be ordered if macros are involved -
# macros need to be defined before they are used.
# A first compiler pass gathers all classes and methods, removing the
# requirement to place these in load order.
#
# When adding new files, use alpha-sort when possible. Make sure
# to also add them to `docs_main.cr` if their content need to
# appear in the API docs.

# This list requires ordered statements

lib LibC
  fun puts(s : UInt8*)
end

require "lib_c"
require "macros"
require "object"
require "comparable"
{% unless flag?(:extreme) %}
require "exception"
{% end %}
require "iterable"
require "iterator"
require "indexable"
require "string"

# Alpha-sorted list
require "array"
require "bool"
require "char"
require "char/reader"
require "class"
require "crystal/main"
require "enum"
require "enumerable"
require "ext"
require "float"
require "int"
require "intrinsics"

{% if flag?(:extreme) %}
require "./gc"

def loop
  while true
    yield
  end
end

ARGV = Array.new(ARGC_UNSAFE - 1) { |i| String.new(ARGV_UNSAFE[1 + i]) }

macro puts(arg)
  LibC.puts(\{{arg}})
end

{% else %}
require "kernel"
{% end %}

require "math/math"
require "named_tuple"
require "nil"
require "number"
require "pointer"
require "primitives"
require "proc"
require "range"
require "reference"
require "slice"
require "static_array"
require "struct"
require "symbol"
require "tuple"
require "value"

{% unless flag?(:regex_none) %}
require "regex"
{% end %}

{% unless flag?(:file_none) %}
require "dir"
require "env"
require "file"
require "random"
require "pretty_print"
{% end %}

{% unless flag?(:time_none) %}
require "time"
{% end %}

{% unless flag?(:hash_none) %}
require "hash"
{% end %}

{% unless flag?(:except_none) %}
require "raise"
{% end %}

{% unless flag?(:fiber_none) %}
require "signal"
require "concurrent"
require "thread"
require "mutex"
require "box"
require "set"
require "process"
require "errno"
require "deque"
{% end %}

{% unless flag?(:extreme) %}
require "atomic"
require "iconv"
require "io"
require "reflect"
require "system"
require "unicode"
require "union"
{% end %}

# require "../../dpdk.cr/src/reset/patches"
