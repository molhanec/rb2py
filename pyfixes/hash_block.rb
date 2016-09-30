#   Hash.new { |h, k| a }
# ==>
#   def _block_XXXX(h, k):
#     a
#   rb2py.hash_block(_block_XXXX)

class HashBlockNode
  attr_accessor :block_name
  def pyfix_hash_block
    #   def _block_XXXX(h, k):
    #     a
    block_name = "_block_#$last_block_id"
    $last_block_id += 1
    # initialize(ruby_node, name, arguments, body)
    block_def = BlockEmulationDefNode.new ruby_node, block_name, arguments, statements
    # block_def.fix_multiple_arguments
    block_def.true_method = false

    # find current statement list
    statement_list, statement_list_child = current_statement_list

    #   rb2py.hash_block(_block_XXXX)
    call = make_rb2py_call 'hash_block', NewValueNode.new(nil, block_name)

    # if we place the block definition just before ourselves
    statement_list_child = call if statement_list_child == self
    statement_list.late_insert before: statement_list_child, node: block_def

    return call
  end
end


class InstantiationNode

  def pyfix_hash_block
    if fullname.to_s == "rb2py.OrderedDict"
      return make_rb2py_call 'hash_block', *children
    end
    return self
  end
end
