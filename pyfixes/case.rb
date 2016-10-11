# case-when control expression

module CaseConditionPyfix

  def pyfix_one_condition(left, right)
    if cmp_against_symbol? left
      return make_rb2py_call 'is_symbol', right
    elsif cmp_against_class? left
      instance_test = InstanceTestNode.new ruby_node, [right, left]
      return instance_test
    end
    def_node = find_surrounding DefNode
    if def_node.regexp_captures
      return make_rb2py_call 'case_cmp', right, left, "rb2py_regexp_captures"
    end
    return make_rb2py_call 'case_cmp', right, left
  end

  def cmp_against_symbol?(value)
    value.is_a? ConstantNode and value.name == 'Symbol'
  end

  def cmp_against_class?(value)
    value.is_a? ConstantNode
  end
end


class CompareCaseNode
  include CaseConditionPyfix

  def pyfix_case
    pyfix_one_condition left, right
  end
end


class WhenNode

  include CaseConditionPyfix

  def pyfix_case
    conditions = values.map {|v| pyfix_one_condition(v, result_var.deep_copy)}
    if conditions.size > 1
      condition = OrNode.new ruby_node, conditions
    else
      condition = conditions[0]
    end
    assign_children [condition, statements]
    self
  end
end


class CaseNode

  def pyfix_case
    ifs_children = []
    else_case = nil
    for child in children[1..-1]
      if child.is_a? WhenNode
        # pyfix_case in WhenNode should have already fixed multiple values into an OrNode
        child.expect_len 2
        ifs_children << [child.values[0], child.statements, MissingNode.new(nil, ruby_node)]
      else
        stop! 'Default case only allowed last' unless child.equal? children[-1]
        else_case = children[-1]
      end
    end

    last_if_children = ifs_children[-1]
    # if there is else clause attach it to the last if statement
    if else_case
      last_if_children[2] = else_case
    else
      # otherwise the default si to set _result to None
      last_if_children[2] = result_assign NilNode.new(ruby_node, [])
    end

    ifs = []
    # first there is
    #   _result = condition
    ifs << result_assign(first_child)
    # first comparison is standard if
    ifs << IfNode.new(ruby_node, ifs_children[0])
    for if_children in ifs_children[1..-1]
      # other comparisons are elif
      d "creating elif"
      if_node = PythonElIf.new ruby_node, if_children
      ifs << if_node
    end

    return ifs
  end
end
