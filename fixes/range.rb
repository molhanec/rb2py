# Ranges

class RangeNode < Node

  alias from first_child
  alias to second_child

  def initialize(ruby_node, children)
    super(ruby_node)
    assign_children children
  end

  def to_s
    'Range'
  end
end


# Three-dot range
class RangeExclusiveNode < RangeNode

  def to_s
    'RangeExclusive'
  end

  def inclusive?
    false
  end
end


# Two-dot range
class RangeInclusiveNode < RangeNode

  def to_s
    'RangeInclusive'
  end

  def inclusive?
    true
  end
end