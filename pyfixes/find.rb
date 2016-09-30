#   array.find {|item| code}
# ==>
#   def _block_XXXX(item):
#     code
#   rb2py.find(_block_XXXX, array)

class FindNode

  def pyfix_find
    block_def, block_name_node = prepare_new_block
    call = make_rb2py_call 'find', block_name_node, target
    insert_new_block block_def, call
    return call
  end
end
