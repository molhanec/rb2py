#   array.partition {|item| code}
# ==>
#   def _block_XXXX(item):
#     code
#   rb2py.partition(_block_XXXX, array)

class PartitionNode

  def pyfix_partition
    block_def, block_name_node = prepare_new_block
    call = make_rb2py_call 'partition', block_name_node, target
    insert_new_block block_def, call
    return call
  end
end
