#   x.inject(y) {|sum, child| b}
# ==>
#   def _block_XXXX(sum, child):
#     b
#   functools.reduce(_block_XXXX, x, y)

class InjectNode
  attr_accessor :block_name
  def pyfix_inject
    #   def _block_XXXX(sum, child):
    #     b
    block_name = "_block_#$last_block_id"
    $last_block_id += 1
    # initialize(ruby_node, name, arguments, body)
    block_def = BlockEmulationDefNode.new ruby_node, block_name, arguments, statements
    block_def.fix_multiple_arguments_inject
    block_def.true_method = false

    # find current statement list
    statement_list, statement_list_child = current_statement_list

    #   functools.reduce(_block_XXXX, x)
    global_target = NewValueNode.new nil, 'functools'
    $pygen.imports << 'functools'
    arg1 = NewValueNode.new nil, block_name
    arg2 = make_rb2py_call 'each', target
    arg3 = initial
    call = SendNode.new ruby_node:ruby_node, target:global_target, message_name:'reduce', arguments:[arg1, arg2, arg3]

    # if we place the block definition just before ourselves
    statement_list_child = call if statement_list_child == self
    statement_list.late_insert before: statement_list_child, node: block_def

    call
  end

  # def get_result; self; end


end

class NoInitializeDefNode
  #  [[1, 2], [3, 4]].inject(f) { |x, a, b| }
  # or
  #  [[1, 2], [3, 4]].inject(f) { |x, (a, b)| } # mlhs
  # ==>
  #  def _block_x(x, args):
  #    a, b = args
  def fix_multiple_arguments_inject
    if arguments.children.size > 2 or (arguments.children.size == 2 and arguments.second_child.is_a? MultipleAssignmentLeftHandSideNode)
      args = SimpleArgumentNode.new arguments.ruby_node, [NewValueNode.new(nil, 'args')]
      assignments = []
      args_expands = []
      for arg in arguments.children[1..-1]
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
      arguments.assign_children [arguments.first_child, *args]
    end
  end
end
