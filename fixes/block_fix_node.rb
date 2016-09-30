
# Common ancestor for Map, Detect, Inject etc.
class BlockFixNode < Node

  attr_reader :argument_names
  alias send_node first_child
  alias send_node= first_child=
  alias arguments second_child
  alias statements third_child

  def target
    send_node.target
  end

  def joined_arguments
    argument_names.size > 0 ? argument_names.join(", ") : 'rb2py_unused'
  end

  def initialize(block)
    super(block.ruby_node)
    assign_children block.children
    @argument_names = block.argument_names
  end
end
