# operator !

class UnprocessedNode
  def make_operator_not
    expect_len 2  # first is the value, second is the operator itself
    value = first_child
    return OperatorNotNode.new ruby_node, value
  end
end


class OperatorNotNode < Node

  alias value child

  def initialize(ruby_node, value)
    super(ruby_node)
    assign_children [value]
  end

  def to_s
    "OperatorNot"
  end
end
