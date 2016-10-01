# Shallow and deep copy

class SendNode

  #   object.clone or object.dup
  # ==>
  #   copy(object)
  def pyfix_shallow_copy
    if ['clone', 'dup'].include? message_name
      new_target = make_rb2py_target
      @message_name = 'shallow_copy'
      assign_children [new_target, *children]
    end
    self
  end


  #   Marshal.load(Marshal.dump(object)))
  # ==>
  #   deepcopy(object)
  def pyfix_deep_copy
    if message_name == 'load' and
        children.size == 2 and
        marshal_class?(target) and
        second_child.is_a? SendNode and
        second_child.message_name == 'dump' and
        marshal_class?(second_child.target) and
        second_child.children.size == 2
      new_target = make_global_target self, ruby_node
      @message_name = 'deepcopy'
      assign_children [new_target, second_child.second_child]
    end
    return self
  end

  # node is Send's target to Marshal class method
  def marshal_class?(node)
    node.is_a? ClassTargetNode and
        node.cls.is_a? EmulatedClassNode and
        node.cls.name == 'Marshal'
  end
end
