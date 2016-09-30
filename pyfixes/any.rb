#   x.any {|a| b}
# ==>
#   def _block_XXXX(a):
#     b
#   rb2py.is_any(_block_XXXX, x)

class AnyNode
  attr_accessor :block_name
  def pyfix_any
    #   def _block_XXXX(a):
    #     b
    block_name = "_block_#$last_block_id"
    $last_block_id += 1
    # initialize(ruby_node, name, arguments, body)
    block_def = BlockEmulationDefNode.new ruby_node, block_name, arguments, statements
    block_def.fix_multiple_arguments
    block_def.true_method = false

    # find current statement list
    statements, statement_list_child = current_statement_list

    #   rb2py.is_any(_block_XXXX, x)
    arg1 = NewValueNode.new(nil, block_name)
    arg2 = target
    any_call = make_rb2py_call 'is_any', arg1, arg2

    # if we place the block definition just before ourselves
    statement_list_child = list_call if statement_list_child == self
    statements.late_insert before: statement_list_child, node: block_def

    return any_call
  end
end
