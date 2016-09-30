class EachWithObjectNode < BlockFixNode
  def initial
    send_node.arguments[0]
  end

  def to_s
    "EachWithObject(#{argument_names})"
  end
end
