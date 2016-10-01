class InstantiationNode

  def pyfix_instantiation
    if class_name == 'Array' and (1..2).include?(argument_count)
      return make_rb2py_call 'list_create_from_size_and_default', *children
    elsif class_name == 'Struct'
      return make_rb2py_call 'Struct', NewValueNode.new(ruby_node, "'#{find_struct_name}'"), *children
    end
    return self
  end

  # In Ruby assigning anonymous class to a constant also assigns the constant as a class name.
  # E.g. Component = Struct.new(...) makes new class named Component
  def find_struct_name
    parent.expect_class ConstantInModuleNode
    return parent.name
  end
end
