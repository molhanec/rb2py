#   method { ... }
# ==>
#   def _block_XXXX():
#     ...
#   method(_block_XXXX)

class CustomBlockNode
  def pyfix_custom_block
    return self if message_name.include? 'each'
    block_def, block_name_node = prepare_new_block
    send_node.assign_children [*send_node.children, block_name_node]
    insert_new_block block_def, send_node
    return send_node
  end
end

