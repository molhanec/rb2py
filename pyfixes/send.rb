#   def f(x=method())
# ==>
#   def f(x=None):
#       if x is None:
#            x = method()

class SendNode

  def pyfix_send_as_default_argument
    if parent.is_a? OptionalArgumentNode
      def_node = find_surrounding DefNode
      nil_test = NilTestNode.new ruby_node, (NewValueNode.new ruby_node, parent.name)
      assign_node = AssignLocalVarNode.new ruby_node, [(NewValueNode.new ruby_node, parent.name), self]
      if_node = IfNode.new ruby_node, [nil_test, StatementListNode.new(nil, [assign_node]), MissingNode.new(nil, nil)]
      def_node.body.assign_children [if_node, *def_node.body.children]
      return NilNode.new ruby_node, []
    end
    return self
  end
end
