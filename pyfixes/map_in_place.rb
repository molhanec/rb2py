#   x.map! {|a| b}
# ==>
#   def _block_XXXX(a):
#     b
#   rb2py.map_in_place(_block_XXXX, x)

class MapInPlaceNode
  attr_accessor :block_name
  def pyfix_map_in_place
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

    # rb2py.map_in_place(_block_XXXX, x)
    arg1 = NewValueNode.new(nil, block_name)
    arg2 = target
    map_in_place_call = make_rb2py_call 'map_in_place', arg1, arg2

    # if we place the block definition just before ourselves
    statement_list_child = map_in_place_call if statement_list_child == self
    statement_list.late_insert before: statement_list_child, node: block_def

    return map_in_place_call
  end

  def get_result; self; end
end
