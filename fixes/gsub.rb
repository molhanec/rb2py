require_relative 'block_fix_node'

class GSubNode < BlockFixNode

  def pattern
    send_node.arguments[0]
  end

  def to_s
    "GSub"
  end

  def cls
    self
  end
end
