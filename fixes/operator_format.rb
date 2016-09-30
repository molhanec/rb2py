# operator %

class UnprocessedNode
  def make_operator_format
    expect_len 3
    format_string = first_child
    values = third_child
    return OperatorFormatNode.new ruby_node, [format_string, values]
  end
end


class OperatorFormatNode < Node

  alias format_string first_child
  alias values second_child

  def initialize(ruby_node, children)
    super(ruby_node)
    assign_children children
  end

  def to_s
    "OperatorFormat"
  end

  def cls
    self
  end
end
