# Todo OpAssignNode should also be AssignGenericNode descendant
class OperatorAssignNode < Node

  attr_reader :operator

  alias target first_child
  alias value third_child

  def initialize(ruby_node, children)
    super(ruby_node)
    assign_children children
  end

  def to_s
    "OperatorAssign(#{operator})"
  end
end
