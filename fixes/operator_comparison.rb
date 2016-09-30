# operators like '>', '>=', '<', '<=', '==', '!='

class UnprocessedNode
  def make_operator_comparison
    expect_len 3
    left = first_child
    operator = second_child
    right = third_child
    return CompareNode.new ruby_node, operator, left, right
  end
end


class CompareNode < Node

  attr_reader :operator

  alias left first_child
  alias right second_child

  def initialize(ruby_node, operator, left, right)
    super()
    @ruby_node = ruby_node
    @operator = operator.load_name
    assign_children [left, right]
  end

  def to_s
    "Compare(#{operator})"
  end
end
