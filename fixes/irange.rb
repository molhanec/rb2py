class UnprocessedNode
  # this one is different: we work on the level above irange which should be begin sexpr

  def fix_irange_in_begin
    if symbol? 'begin' and children.size == 1 and child.symbol? 'irange'
      return IRangeNode.new child
    end
    self
  end
end



class IRangeNode < Node

  alias from first_child
  alias to second_child

  def initialize(irange_node)
    super(irange_node.ruby_node)
    irange_node.expect_len 2
    assign_children irange_node.children
  end

  def to_s
    'IRange'
  end

  def cls; self; end
end
