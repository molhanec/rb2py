# defined? operator

class UnprocessedNode
  def fix_defined
    return self unless symbol? 'defined?'
    expect_len 1
    return DefinedNode.new ruby_node, children
  end
end


class DefinedNode < Node

  def initialize(ruby_node, children)
    super(ruby_node)
    assign_children children
  end

  def to_s
    'Defined'
  end
end
