#   x.detect {|a| b}
# ==>
#   def _block_XXXX(a):
#     b
#   rb2py.detect(_block_XXXX, x)

class DetectNode
  attr_accessor :block_name
  def pyfix_detect
    #   def _block_XXXX(a):
    #     b
    block_name = "_block_#$last_block_id"
    $last_block_id += 1
    # initialize(ruby_node, name, arguments, body)
    block_def = BlockEmulationDefNode.new ruby_node, block_name, arguments, statements
    block_def.fix_multiple_arguments
    block_def.true_method = false

    # find current statement list
    statement_list, statement_list_child = current_statement_list

    #   rb2py.detect(block_XXXX, x)
    send_node.expect_no_arguments # defaults currently unimplemented
    arg1 = NewValueNode.new(nil, block_name)
    arg2 = target
    call = make_rb2py_call 'detect', arg1, arg2

    # if we place the block definition just before ourselves
    statement_list_child = call if statement_list_child == self
    statement_list.late_insert before: statement_list_child, node: block_def

    return call
  end
end
