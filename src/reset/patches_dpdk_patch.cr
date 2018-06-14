# :nodoc:
{% skip_file() unless flag?(:extreme) %}

require "./lib_c"

{% unless flag?(:fiber_none) %}
fun _fiber_get_stack_top : Void*
  Pointer(Void).null
end

{% end %}
