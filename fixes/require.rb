class UnprocessedNode
  def make_require
    expect_len 3
    first_child.expect_missing # should be global send
    second_child.expect 'require'
    third_child.expect_class StringNode
    # StringNode contains StringLeafNode so apply value() twice
    name = third_child.value.value
    RequireNode.new ruby_node, name
  end
end


class RequireNode < Node

  attr_reader :name

  def initialize(ruby_node, name)
    super(ruby_node)
    @name = name
  end

  def to_s
    "Require(#{name})"
  end
end
