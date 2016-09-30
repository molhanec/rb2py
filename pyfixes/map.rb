#   x.map {|a| b}
# ==>
#   def _block_XXXX(a):
#     b
#   list(map(_block_XXXX, x))

$last_block_id = 1

class MapNode
  attr_accessor :block_name
  def pyfix_map
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

    #   map(_block_XXXX, x)
    # global_target = make_global_target parent, ruby_node
    arg1 = NewValueNode.new(nil, block_name)
    arg2 = target
    map_call = make_rb2py_call 'map', arg1, arg2
    # map_call = SendNode.new ruby_node:ruby_node, target:global_target, message_name:'map', arguments:[arg1, arg2]
    # list_call = SendNode.new ruby_node:ruby_node, target:global_target, message_name:'list', arguments:[map_call]

    # if we place the block definition just before ourselves
    # statement_list_child = list_call if statement_list_child == self
    statement_list_child = map_call if statement_list_child == self
    statement_list.late_insert before: statement_list_child, node: block_def

    # list_call
    return map_call
  end
end
