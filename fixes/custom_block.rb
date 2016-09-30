#   x.method(y) {|i| b}
class CustomBlockNode < BlockFixNode

  def message_name
    send_node.message_name
  end

  def to_s
    "CustomBlock(#{message_name})"
  end

  def fix_block_calls; self end
end
