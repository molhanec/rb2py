#   array.delete_if { |item| a }
# ==>
#   def _block_XXXX(item):
#     a
#   rb2py.delete_if(_block_XXXX, array)

class DeleteIfNode
  attr_accessor :block_name
  def pyfix_delete_if
    #   def _block_XXXX(item):
    #     a
    block_name = "_block_#$last_block_id"
    $last_block_id += 1
    # initialize(ruby_node, name, arguments, body)
    block_def = BlockEmulationDefNode.new ruby_node, block_name, arguments, statements
    block_def.true_method = false

    # find current statement list
    statement_list, statement_list_child = current_statement_list

    #   rb2py.delete_if(_block_XXXX, array)
    call = make_rb2py_call 'delete_if', target, NewValueNode.new(nil, block_name)

    # if we place the block definition just before ourselves
    statement_list_child = call if statement_list_child == self
    statement_list.late_insert before: statement_list_child, node: block_def

    return call
  end
end
