#  [[1, 2], [3, 4]].map { |a, b| }
# or
#  [[1, 2], [3, 4]].map { |(a, b)| } # represented in AST as mlhs
# ==>
#  def _block_x(args):
#    a, b = args

class NoInitializeDefNode
  def fix_multiple_arguments
    if arguments.children.size > 1 or (arguments.children.size == 1 and arguments.child.is_a? MultipleAssignmentLeftHandSideNode)
      args = SimpleArgumentNode.new arguments.ruby_node, [NewValueNode.new(nil, 'args')]
      assignments = []
      args_expands = []
      for arg in arguments.children
        if arg.is_a? MultipleAssignmentLeftHandSideNode
          args_expands += arg.children
        else
          args_expands << arg
        end
      end
      args_expands.each_with_index do
        |argument, index|
        assignments << AssignArgumentVarNode.new(argument.ruby_node, [argument, NewValueNode.new(nil, "args[#{index}]")])
      end
      body.children.insert 0, *assignments
      assignments.each {|assignment| assignment.parent = body}
      arguments.assign_children [args]
    end
  end
end


# don't generate _result assignments for this
class AssignArgumentVarNode < AssignLocalVarNode
  def get_result
    self
  end
end
