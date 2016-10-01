class Node

  # Returns first statement list above current node and the child which leads to the current node (or self if we
  # are directly in the statement list)
  def current_statement_list
    statement_list_child = self
    until statement_list_child.parent.is_a? StatementListNode or statement_list_child.parent.is_a? ClassNode
      statement_list_child = statement_list_child.parent
    end
    return statement_list_child.parent, statement_list_child
  end
end
