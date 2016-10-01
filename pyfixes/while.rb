#   while var = method()
#     code
#   end
# ==>
#   _while_var_X = method()
#   var = while_var_X
#   while _while_var_X:
#       code
#       _while_var_X = method()
#       var = while_var_X

require_relative 'def'

$while_var_id = 0
class WhileNode

  # Handles assignment inside condition
  def get_result

    statements.expect_class StatementListNode
    statements.get_result

    # if the whole condition is inside parens, remove them
    if condition.is_a? BeginNode
      condition.expect_len 1
      self.condition = condition.child
    end
    unless condition.is_a? ExpressionIsAlsoExpressionInPython
      # find current statement list
      statements_list, statement_list_child = current_statement_list

      # before while
      #   _while_var_X = method()
      #   var = while_var_X
      condition_expr = nil
      while_var_mask_result do
        condition_expr = condition.get_result
        statements_list.late_insert before: statement_list_child, node: condition_expr
      end

      #   while _while_var_X:
      self.condition = while_var.deep_copy

      # add again on the end of statement list
      #   _while_var_X = method()
      #   var = while_var_X
      while_var_mask_result do
        for node in condition_expr
          statements.add_child node.deep_copy
        end
      end
    end
    return self
  end

  def while_var
    @while_var ||= LocalVariableNode.new ruby_node, [SimpleName.new(while_var_name)]
  end

  def while_var_name
    @while_var_name ||= "_while_var_#{$while_var_id += 1}"
  end

  def while_var_mask_result
    backup = $result_name, $result_var
    $result_name, $result_var = while_var_name, while_var
    yield
    $result_name, $result_var = backup
  end
end
