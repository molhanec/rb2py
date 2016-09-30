# operators '+@', '-@', '~'

class UnprocessedNode
  def make_operator_unary
    expect_len 2
    value = first_child
    operator = second_child
    return OperatorUnaryNode.new ruby_node, operator, value
  end
end


class OperatorUnaryNode < Node

  attr_reader :operator

  alias value child

  def initialize(ruby_node, operator, value)
    super(ruby_node)
    @operator = operator.load_name[0] # strip @
    assign_children [value]
  end

  def to_s
    "OperatorUnary(#{operator})"
  end

  def cls
    self
  end
end
