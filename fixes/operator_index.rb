# operators [], []=

require_relative 'subexpression'

class UnprocessedNode

  def make_operator_index
    container = first_child
    indices = children[2..-1]
    return IndexNode.new ruby_node, [container, *indices]
  end

  def make_operator_index_assign
    expect_min_len 3, msg:"Children: #{children.inspect}"
    container = first_child

    # second child is the []= symbol

    if children.size >= 4
      # third to second-to-last child are indices
      indices = children[2..-2]
      value = last_child
    else
      # part of multiple assignment
      indices = children[2..-1]
      value = MissingNode.new ruby_node
    end
    return IndexAssignNode.new ruby_node, container, indices, value
  end
end


class IndexAncestorNode < SubexpressionNode

  alias container first_child
  def indices
    children[1..-1]
  end

  def to_s
    'IndexAncestor'
  end
end


class IndexNode < IndexAncestorNode

  def initialize(ruby_node, children)
    super()
    @ruby_node = ruby_node
    assign_children children
  end

  def to_s
    'Index'
  end

  def cls
    nil
  end
end


class IndexAssignNode < IndexAncestorNode

  alias container first_child

  alias value last_child
  alias value= last_child=

  def indices
    children[1..-2]
  end

  def initialize(ruby_node, container, indices, value)
    super()
    @ruby_node = ruby_node
    assign_children [container, *indices, value]
  end

  def to_s
    'IndexAssign'
  end

  def cls
    nil
  end
end
