# Solves problem, that the last expression of method is method's return value

class Node

  def result_name
    $result_name ||= SimpleName.new('_result')
  end

  def result_var
    $result_var ||= LocalVariableNode.new ruby_node, [result_name]
    $result_var.deep_copy
  end

  def result_assign(value_node)
    AssignLocalVarNode.new(ruby_node, [result_var, value_node])
  end

  unless $require_implemented_get_result
    def get_result; self; end
  end
end


class DefNode

  def pyfix_def
    body.expect_class StatementListNode
    assignment = result_assign NilNode.new(ruby_node, [])
    body.get_result
    body.unshift assignment
    body << ReturnNode.new(ruby_node, [result_var]) unless initialize?
    return self
  end
end


# Used by Node#result_name
class SimpleName < Node
  attr_accessor :name
  def initialize(name)
    super()
    @name = name
  end
  alias load_name name
end


####################################################################
# Mixins


# This node represents expression in Ruby, not in Python
# E.g. assignment
#    a = 5
# ==>
#    _result = 5
#    a = _result
module ExpressionInRubyNotInPython
  def get_result
    assignment = result_assign value
    self.value = result_var
    return [assignment, self]
  end
end


# This node represents expression in both languages
# E.g. method call
#   a()
# ==>
#   _result = a()
module ExpressionIsAlsoExpressionInPython
  def get_result
    [result_assign(self)]
  end
end


# This node result value is actually result value of children
# E.g. if statement
#   if a then f(); end
# ==>
#   if a: _result = f()
module ResultIsValueOfChildren
  def get_result
    children.each {|c| c.get_result }
    return self
  end
end


# Not an expression at all => do nothing
# E.g. return statement
module StatementNotExpression
  def get_result
    self
  end
end


# Moves node to the nearest statement list if not already in a statement list
module MoveFromSubexpression
  def pyfix_subexpression
    if parent.is_a? SubexpressionNode
      statements, statement_list_child = current_statement_list
      statements.late_insert before: statement_list_child, node: self
      return result_var
    end
    return self
  end
end


####################################################################


class AndNode
  include ExpressionIsAlsoExpressionInPython
end


class ArrayNode
  include ExpressionIsAlsoExpressionInPython
end


class AssignClassVarNode
  include ExpressionInRubyNotInPython
end


class AssignInstanceAttrNode
  include ExpressionInRubyNotInPython
end


class AssignInstanceVarNode
  include ExpressionInRubyNotInPython
end


class AssignLocalVarNode
  include ExpressionInRubyNotInPython
  def get_result
    value_name = nil
    begin
      value_name = value.name
    rescue
    end
    if name == '_result' or value_name == '_result'
      self
    elsif value.is_a? IfNode
      value.get_result
      return [value, AssignLocalVarNode.new(ruby_node, [NewValueNode.new(nil, name), result_var])]
    else
      super()
    end
  end
end


class BeginNode
  include ExpressionIsAlsoExpressionInPython
end


class BlockGivenTestNode
  include ExpressionIsAlsoExpressionInPython
end

class BreakNode
  include StatementNotExpression
end

class CaseNode
  include MoveFromSubexpression
end

class CompareNode
  include ExpressionIsAlsoExpressionInPython
end


class ConstantNode
  include ExpressionIsAlsoExpressionInPython
end


class CustomBlockNode
  def get_result
    statements.get_result
    return self
  end

  def pyfix_subexpression
    unless parent.is_a? StatementListNode
      statements, statement_list_child = current_statement_list
      statements.late_insert before: statement_list_child, node: self
      return result_var
    end
    return self
  end
end


class DefNode
  include StatementNotExpression
end


class EachNode
  def get_result
    statements.get_result
    return [self, result_assign(target.deep_copy)]
  end
end


class EnsureNode
  include ResultIsValueOfChildren
end


class FalseNode
  include ExpressionIsAlsoExpressionInPython
end


class FloatNode
  include ExpressionIsAlsoExpressionInPython
end


class HashNode
  include ExpressionIsAlsoExpressionInPython
end

class IndexNode
  include ExpressionIsAlsoExpressionInPython
end

class IndexAssignNode
  include ExpressionInRubyNotInPython
end

class InstantiationNode
  include ExpressionIsAlsoExpressionInPython
end

class InstanceTestNode
  include ExpressionIsAlsoExpressionInPython
end

class InstanceVariableNode
  include ExpressionIsAlsoExpressionInPython
end

class IntNode
  include ExpressionIsAlsoExpressionInPython
end

class LocalVariableNode
  include ExpressionIsAlsoExpressionInPython
end

class LoopNode
  include StatementNotExpression
end

class MatchNode
  include ExpressionIsAlsoExpressionInPython
end

class MultipleAssignmentNode
  def get_result
    assignment = result_assign rights
    self.rights = result_var
    [assignment, self]
  end
end

class NextNode
  include StatementNotExpression
end


class NewValueNode
  include ExpressionIsAlsoExpressionInPython
end


class NilNode
  include ExpressionIsAlsoExpressionInPython
end


class NilTestNode
  include ExpressionIsAlsoExpressionInPython
end


class OperatorAppendNode
  include ExpressionIsAlsoExpressionInPython
end


class OperatorBinaryNode
  include ExpressionIsAlsoExpressionInPython
end


class OperatorFormatNode
  include ExpressionIsAlsoExpressionInPython
end


class OperatorNotNode
  include ExpressionIsAlsoExpressionInPython
end


class OperatorUnaryNode
  include ExpressionIsAlsoExpressionInPython
end


class OrNode
  include ExpressionIsAlsoExpressionInPython
end


class SelfNode
  include ExpressionIsAlsoExpressionInPython
end


class SendNode
  include ExpressionIsAlsoExpressionInPython
end


class StatementListNode
  def get_result
    new_children = children.collect &:get_result
    assign_children new_children.flatten
    return self
  end
end


class StringInterpolatedNode
  include ExpressionIsAlsoExpressionInPython
end


class SymbolNode
  include ExpressionIsAlsoExpressionInPython
end


class RaiseNode
  include StatementNotExpression
end


class RescueBodyNode
  def get_result
    statements.get_result
    return self
  end
end


class RescueNode
  include ResultIsValueOfChildren
end


class ReturnNode
  include StatementNotExpression
end


class StringNode
  include ExpressionIsAlsoExpressionInPython
end


class SuperNode
  include StatementNotExpression
end


class SuperWithoutArgsNode
  include StatementNotExpression
end


class TimesNode
  def get_result
    statements.get_result
    [self, result_assign(target.deep_copy)]
  end
end


class TrueNode
  include ExpressionIsAlsoExpressionInPython
end


class YieldNode
  include StatementNotExpression
end


class UntilNode
  include StatementNotExpression
end


class UptoNode
  def get_result
    statements.get_result
    [self, result_assign(from.deep_copy)]
  end
end
