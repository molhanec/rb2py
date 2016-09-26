# Fixes and/or logic expressions

#   x = a() or b()
# ==>
#   _and_or_var_X = a()
#   x = _and_or_var_X if ruby_true(_and_or_var_X) else b()

#   x = a() and b()
# ==>
#   _and_or_var_X = a()
#   x = b() if ruby_true(_and_or_var_X) else _and_or_var_X

require_relative 'ternary'

# Counter for creating unique variable name
$and_or_var_id = 0

module AndOrPyfix

  # Are we interested just in true/false or we need also the value of an and/or expression?
  def inside_subexpression?
    current = previous = self
    while current = current.parent
      case current

        # Expression inside another expression
        when
          AndNode,
          BeginNode,
          ExpressionNode,
          OrNode # must precede OrAssignNode test, because OrAssignNode inherits from OrNode
          then
          # we cannot decide for these node classes, silently fall outside case and continue search in parent

        # We need value of and/or
        when
          ArrayNode,
          InstantiationNode,
          OrAssignNode,
          PairNode,
          ReturnNode,
          SendNode,
          StatementListNode,
          StringInterpolatedNode,
          SubexpressionNode
          then return true

        # We don't need value of and/or, just true or false
        when
          CaseNode,
          WhileNode
          then return false

        when
          IfNode,
          PythonTernary
          then
            # For condition true/false is enough, we don't need value
            if previous == current.condition
              return false
            # We need value for the ternary expressions executed when true/false.
            # Note that for IfNode, when_true/when_false are StatementLists, so we never get here,
            # because we already returned true above for StatementList.
            elsif (previous == current.when_true) or (previous == current.when_false)
              return true
            else
              stop! "Unknown child of IfNode"
            end
        else
          stop! "Unknown parent of 'and' or 'or': '#{current}'"
      end
      previous = current
    end

    stop! "Unknown parent of 'and' or 'or'. Search exhausted."
  end


  def and_or_var
    @and_or_var ||= LocalVariableNode.new ruby_node, [SimpleName.new(and_or_var_name)]
    return @and_or_var.deep_copy
  end

  def and_or_var_name
    @and_or_var_name ||= "_and_or_var_#{$and_or_var_id += 1}"
  end

  def and_or_var_assign(value_node)
    AssignLocalVarNode.new(ruby_node, [and_or_var, value_node])
  end
end

class AndNode
  include AndOrPyfix

  #   x = a() and b()
  # ==>
  #   _and_or_var_X = a()
  #   x = b() if ruby_true(_and_or_var_X) else _and_or_var_X
  def pyfix_and_or
    return self unless inside_subexpression?
    left_eval = and_or_var_assign left
    ternary = PythonTernary.new [
                                    and_or_var, # condition
                                    right, # when true
                                    and_or_var # when false
                                ]
    statement_list, statement_list_child = current_statement_list
    statement_list_child = ternary if statement_list_child == self
    statement_list.late_insert before: statement_list_child, node: left_eval
    return ternary
  end
end

class OrNode
  include AndOrPyfix

  #   x = a() or b()
  # ==>
  #   _and_or_var_X = a()
  #   x = _and_or_var_X if ruby_true(_and_or_var_X) else b()
  def pyfix_and_or
    return self unless inside_subexpression?
    left_eval = and_or_var_assign left
    ternary = PythonTernary.new [
                                    and_or_var, # condition
                                    and_or_var, # when true
                                    right # when false
                                ]
    statement_list, statement_list_child = current_statement_list
    statement_list_child = ternary if statement_list_child == self
    statement_list.late_insert before: statement_list_child, node: left_eval
    return ternary
  end
end
