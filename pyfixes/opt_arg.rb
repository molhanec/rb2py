# In Python, default argument values are evaluated just once when the interpreter sees the definition. The resulting
# object is then reused. In Ruby it is evaluated on each call.
#
#   def f(a=b())
# ==>
#   def f(a=None):
#     if a is None:
#        a = b()
#
# As a side effect, you can in Ruby also use value of previous argument.
#
#   def f(a, b=a)
# ==>
#   def f(a, b=None):
#     if b is None:
#       b = a
class OptionalArgumentNode

  def pyfix_opt_arg
    unless default_value.constant_value?
      nil_test = NilTestNode.new ruby_node, first_child.deep_copy # name node
      assign = AssignLocalVarNode.new ruby_node, [first_child.deep_copy, default_value]
      if_node = IfNode.new ruby_node, [nil_test, assign, MissingNode.new]
      def_node = find_surrounding DefNode
      def_node.body.prepend_child if_node
      self.default_value = NilNode.new ruby_node, []
    end
    return self
  end
end


class Node
  def constant_value?
    false
  end
end


class NilNode
  def constant_value?
    true
  end
end


class TrueNode
  def constant_value?
    true
  end
end


class FalseNode
  def constant_value?
    true
  end
end


class IntNode
  def constant_value?
    true
  end
end
