#   a ||= begin
#     x
#   end
# ==>
#   def _block_XXXX():
#     return x
#   a = a or _block_XXXX()

class BeginKeywordNode
  attr_accessor :block_name
  def pyfix_kwbegin
    unless parent.is_a? OrAssignNode or parent.is_a? ConstantInModuleNode
      stop! "Unexpected keyword 'begin'"
    end
    #   def _block_XXXX():
    block_name = "_block_#$last_block_id"
    $last_block_id += 1
    # initialize(ruby_node, name, arguments, body)
    block_def = BlockEmulationDefNode.new ruby_node, block_name, (ArgumentListNode.new ruby_node, []), make_statement_list
    block_def.true_method = false

    # find current statement list
    statement_list, statement_list_child = current_statement_list

    #   a = a or _block_XXXX()
    call = NewValueNode.new ruby_node, "#{block_name}()"

    # if we place the block definition just before ourselves
    statement_list_child = call if statement_list_child == self
    statement_list.late_insert before: statement_list_child, node: block_def

    return call
  end
end
