# collection.any? { block }

require_relative 'block_fix_node'

class AnyNode < BlockFixNode

  def to_s
    "Any(#{argument_names})"
  end

  def cls
    self
  end
end
