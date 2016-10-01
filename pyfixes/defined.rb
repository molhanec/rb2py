class DefinedNode
  def pyfix_defined
    expect_len 1
    unless child.is_a? InstanceVariableNode
      stop! 'Only instance variables currently supported for defined'
    end
    object = SelfNode.new ruby_node
    var_name = "'#{child.name}'"
    return make_rb2py_call 'is_defined_instance_var', object, NewValueNode.new(ruby_node, var_name)
  end
end
