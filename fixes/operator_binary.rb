# operators like '+', '-', '*', '/', '**', '&', '|', '^', '>>'

require_relative 'subexpression'

class Node
  def make_operator_binary
    expect_len 3
    left = first_child
    operator = second_child
    right = third_child
    return OperatorBinaryNode.new ruby_node, operator, left, right
  end
end


class OperatorBinaryNode < SubexpressionNode

  attr_reader :operator

  alias left first_child
  alias right second_child

  def initialize(ruby_node, operator, left, right)
    super(ruby_node)
    @operator = operator.load_name
    assign_children [left, right]
  end

  def to_s
    "OperatorBinary(#{operator})"
  end

  def cls; nil end
end
