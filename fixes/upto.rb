#   x.upto(y) {|i| b}
# ==>
#   for i in range(x, y + 1):
#     b

class UptoNode < BlockFixNode

  alias from first_child
  alias to second_child
  alias statements third_child


  def initialize(block)
    super(block)
    assign_children [block.target, block.send_node.arguments[0], block.statements]
    @argument_names = block.argument_names
  end

  def to_s
    "Upto(#{argument_names})"
  end

  def fix_block_calls; self end
end
