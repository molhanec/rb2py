require_relative 'late_inserter'

class Node

  # This works quite different from other fixes.
  # This is also why it is called make_ and not fix_.
  # In the input Ruby AST, like classic Pascal
  # you have either single statement or begin block.
  # So if we get begin Node, we just replace it with
  # StatementListNode, otherwise we consider Node as
  # a single statement and wrap it inside StatementListNode
  # which will have the original node as a single child.
  def make_statement_list
    if symbol? 'begin' or is_a? BeginNode or is_a? BeginKeywordNode
      children = @children
    else
      children = [self]
    end
    return StatementListNode.new ruby_node, children
  end

end


# Transform Missing node into empty statement list.
# This is used by empty "else" clause.
class MissingNode
  def make_statement_list
    StatementListNode.new ruby_node, []
  end
end


class StatementListNode < Node

  include LateInserter

  def initialize(ruby_node, children)
    super()
    @ruby_node = ruby_node
    assign_children children
  end

  def to_s
    "StatementList(#{@children.size})"
  end

  def empty?
    children.size == 0
  end

  def unshift(what)
    children.unshift what
    what.parent = self
  end

  def <<(what)
    children << what
    what.parent = self
  end
end
