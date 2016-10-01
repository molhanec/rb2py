class Node
  def make_expression
    return self unless symbol? 'begin'
    return ExpressionNode.new @ruby_node, children
  end
end


class ExpressionNode < Node

  def initialize(ruby_node, children)
    super()
    @ruby_node = ruby_node
    assign_children children
  end

  def to_s
    "Expression"
  end
end
