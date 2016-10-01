# ||= operator

class UnprocessedNode
  def fix_or_assign
    return self unless symbol? 'or_asgn'
    expect_len 2
    return OrAssignNode.new ruby_node, children
  end
end


class OrAssignNode < Node

  alias left first_child
  alias right second_child

  def initialize(ruby_node, children)
    super(ruby_node)
    assign_children children
  end

  def to_s
    'OrAssign'
  end

  def cls
    self
  end
end
