class TimesNode < BlockFixNode

  attr_reader :argument_names
  alias target first_child
  alias statements second_child

  def initialize(block)
    super(block)
    assign_children [block.target, block.statements]
    @argument_names = block.argument_names
  end

  def to_s
    "Times(#{argument_names})"
  end

  def fix_block_calls; self end
end
