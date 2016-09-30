# operator ===

class UnprocessedNode
  def make_operator_case_comparison
    expect_len 3
    left = first_child
    right = third_child
    return CompareCaseNode.new ruby_node, left, right
  end
end


class CompareCaseNode < Node

  alias left first_child
  alias right second_child

  def initialize(ruby_node, left, right)
    super(ruby_node)
    assign_children [left, right]
  end

  def to_s
    "CompareCase"
  end
end
