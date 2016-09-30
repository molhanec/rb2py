# operator <<

class UnprocessedNode
  def make_operator_append
    expect_len 3 # target << arguments
    target = first_child
    value = third_child
    return OperatorAppendNode.new ruby_node, [target, value]
  end
end


class OperatorAppendNode < Node

  alias value child

  def initialize(ruby_node, children)
    super(ruby_node)
    assign_children children
  end

  def to_s
    'OperatorAppend'
  end
end
