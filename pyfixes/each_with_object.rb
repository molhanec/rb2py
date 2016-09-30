#   array.each_with_object {|item, object| code}
# ==>
#   def _block_XXXX(item, object):
#     code
#   rb2py.each_with_object(_block_XXXX, array, object)

class EachWithObjectNode

  def pyfix_each_with_object
    block_def, block_name_node = prepare_new_block
    call = make_rb2py_call 'each_with_object', block_name_node, target, initial
    insert_new_block block_def, call
    return call
  end
end
