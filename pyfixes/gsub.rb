#   string.gsub(pattern) {|match| code}
# ==>
#   def _block_XXXX(match):
#     code
#   rb2py.gsub(_block_XXXX, string, pattern)

class GSubNode
  attr_accessor :block_name
  def pyfix_gsub
    block_def, block_name_node = prepare_new_block
    statement_list, statement_list_child = current_statement_list

    # rb2py.gsub(_block_XXXX, string, pattern)
    call = make_rb2py_call 'gsub', block_name_node, target, pattern

    # if we place the block definition just before ourselves
    statement_list_child = call if statement_list_child == self
    statement_list.late_insert before: statement_list_child, node: block_def

    call
  end
end
