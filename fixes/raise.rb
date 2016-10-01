class RaiseNode < Node

  def initialize(ruby_node, children, class_name:nil)
    super()
    @ruby_node = ruby_node

    if class_name
      # Make it simple to create RaiseNode instances by hand
      cls_name = class_name
      new_children = children
    else
      cls = children[0]
      if cls.is_a? StringNode or cls.is_a? StringInterpolatedNode
        cls_name = 'rb2py.Exception'
        new_children = children
      else
        cls_name = cls.load_name
        new_children = children[1..-1]
      end
    end
    exception_object = InstantiationNode.new cls.ruby_node, cls_name, new_children
    assign_children [exception_object]
  end

  def to_s
    "Raise"
  end
end
