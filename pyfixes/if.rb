$if_var_id = 0
class IfNode

  def pyfix_subexpression
    if parent.is_a? SubexpressionNode
      unless when_false.children.size > 0
        when_false.assign_children [(result_assign NewValueNode.new(nil, 'None'))]
      end
      statements, statement_list_child = current_statement_list
      statements.late_insert before: statement_list_child, node: self
      return result_var
    end
    return self
  end

  # Handles assignment inside condition
  def get_result
    # if the whole condition is inside parens, remove them
    if condition.is_a? BeginNode
      condition.expect_len 1
      self.condition = condition.child
    end
    unless condition.is_a? ExpressionIsAlsoExpressionInPython
      # find current statement list
      statements, statement_list_child = current_statement_list
      if_var_mask_result {
        condition_expr = condition.get_result
        statements.late_insert before: statement_list_child, node: condition_expr
      }
      self.condition = if_var.deep_copy
    end
    when_true.expect_class StatementListNode
    when_true.get_result
    when_false.expect_class StatementListNode
    when_false.get_result
    return self
  end

  def if_var_assign(value_node)
    AssignLocalVarNode.new(ruby_node, [if_var, value_node])
  end

  def if_var
    @if_var ||= LocalVariableNode.new ruby_node, [SimpleName.new(if_var_name)]
  end

  def if_var_name
    @if_var_name ||= "_if_var_#{$if_var_id += 1}"
  end

  def if_var_mask_result
    backup = $result_name, $result_var
    $result_name, $result_var = if_var_name, if_var
    yield
    $result_name, $result_var = backup
  end
end
