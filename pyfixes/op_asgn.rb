#   a OP= b
# ==>
#   _result = a OP b
#   a = _result

class OperatorAssignNode
  def pyfix_op_assign
    if inside_initialize?
      if parent.is_a? StatementListNode
        return self
      else
        stop! "operator-assign inside initialize not in a statement list"
      end
    end

    assign_from_result, getter = case first_child
      when AssignInstanceVarNode, AssignLocalVarNode
        first_child.value = result_var
        [first_child, first_child.getter]
      when IndexNode
        [result_assign(make_rb2py_call 'set_index', *first_child.deep_copy.children, result_var), first_child]
      when SendNode
        if first_child.message_name == 'get_index'
          # copy children without original target (rb2py)
          [result_assign(make_rb2py_call 'set_index', *first_child.deep_copy.children[1..-1], result_var), first_child]
        else
          [
            SendNode.new(
              ruby_node:ruby_node,
              target:first_child.target.deep_copy,
              message_name:(make_setter_name first_child.message_name),
              arguments:[result_var]),
            first_child
          ]
        end
      else
        stop! "pyfix_op_assign unknown first_child #{first_child.inspect}"
    end
    assign_to_result = result_assign(OperatorBinaryNode.new ruby_node, second_child, getter, value)

    if parent.is_a? StatementListNode
      return [assign_to_result, assign_from_result]
    else
      statement_list, statement_list_child = current_statement_list
      statement_list.late_insert before: statement_list_child, node: [assign_to_result, assign_from_result]
      return result_var
    end
  end

  def get_result; self; end

  def gen
    if inside_initialize?
      first_child.gen
      $pygen.write ' '
      second_child.gen
      $pygen.write '= '
      third_child.gen
    else
      stop! "OperatorAssign#gen outside initialize"
    end
  end
end
