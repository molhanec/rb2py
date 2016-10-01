#   left ||= right
# ==>
#   _result = left
#   if rb2py.ruby_false(_result):
#     _result = right
#     left = _result
#
# Does not handle uninitialized instance variables.

require_relative 'op_index_in_assign'

class OrAssignNode

  def transform_left
    case left
      when AssignClassVarNode
        return ClassVariableNode.new left.ruby_node, left.children
    end
    return left.deep_copy
  end

  def pyfix_or_assign
    # _result = left
    result_assign_node = result_assign transform_left

    # rb2py.ruby_false(_result)
    condition = make_rb2py_call 'ruby_false', result_var

    # _result = right
    assign_node = result_assign right

    # left = _result
    if left.is_a? IndexNode
      left_assign = make_rb2py_call 'set_index', *(left.children), result_var
    else
      left.value = result_var
      left_assign = left
    end

    # if condition:
    if_node = IfNode.new ruby_node, [condition, StatementListNode.new(nil, [assign_node, left_assign]), MissingNode.new(nil, nil)]

    # if_node.get_result
    result = [result_assign_node, if_node]

    if parent.is_a? StatementListNode
      # We are directly in the statement list
      return result
    end

    # find current statement list
    statement_list, statement_list_child = current_statement_list
    statement_list.late_insert before: statement_list_child, node: result

    return result_var
  end

  def real_gen
    stop! "OrAssignNode::real_gen"
  end
end
