# If we known from static analysis that the target (variable) is an array, we can generate more succint code

require_relative 'custom_methods_call'

class SendNode < SubexpressionNode

  def pyfix_array
    return self unless target_class? ArrayNode
    case message_name
      when 'detect' then pyfix_array_detect
      when 'dup' then self # handled by shallow copy
      when 'each' then return self # We are inside EachNode
      when 'each_with_index' then return self # We are inside EachWithIndexNode
      when 'empty?' then pyfix_array_empty
      when 'first' then pyfix_array_first
      when 'index' then pyfix_array_index
      when 'inject' then pyfix_array_inject
      when 'insert' then pyfix_array_insert
      when 'last' then pyfix_array_last
      when 'length' then pyfix_array_size
      when 'map' then pyfix_array_map
      when 'push' then pyfix_array_push
      when 'size' then pyfix_array_size
      when 'width' then self # FIXME error in static analysis
      else
        if CUSTOM_METHODS_CALL.include? message_name
          self
        else
          stop! "Unknown array method #{message_name}"
        end
    end
  end

  def pyfix_array_detect
    expect_no_arguments
    return self
  end

  # a.empty? ==> rb2py.array_empty(a)
  def pyfix_array_empty
    expect_no_arguments
    return make_rb2py_call 'array_empty', self.target
  end

  # a.first ==> rb2py.array_first(a)
  def pyfix_array_first
    expect_no_arguments
    return make_rb2py_call 'array_first', self.target
  end

  def pyfix_array_index
    expect_arguments_count 1
    return self
  end

  def pyfix_array_inject
    expect_arguments_count 1
    return self
  end

  def pyfix_array_insert
    expect_arguments_count 2
    return self
  end

  # a.last ==> rb2py.array_last(a)
  def pyfix_array_last
    expect_no_arguments
    return make_rb2py_call 'array_last', self.target
  end

  def pyfix_array_map
    return self
  end

  #   x.push(y)
  # ==>
  #   x.append(y)
  #   $result = x
  def pyfix_array_push
    @message_name = 'append'
    [self, target.deep_copy]
  end

  def pyfix_array_replace
    expect_arguments_count 1
    PythonArrayReplaceNode.new self
  end

  def pyfix_array_size
    expect_no_arguments
    global_target = make_global_target self, ruby_node
    @message_name = 'len'
    assign_children [global_target, target]
    self
  end
end


#   array.replace(another_array)
# ==>
#   array[:] = another_array
class PythonArrayReplaceNode < Node

  alias send_node child

  def initialize(send_node)
    super(send_node.ruby_node)
    assign_children [send_node]
  end

  def to_s
    'PythonArrayReplaceNode'
  end

  def real_gen
    send_node.target.gen
    $pygen.write '[:] = '
    # send_node.arguments.gen
    $pygen.write '_result = '
    send_node.mark_ungenerated
    send_node.gen
  end
end
