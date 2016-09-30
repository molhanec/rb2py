class EachNode < BlockFixNode

  def to_s
    "Each(#{argument_names})"
  end

  def fix_block_calls; self end

  def reversed?
    false
  end
end


class EachWithIndexNode < EachNode
  def to_s
    "EachWithIndex(#{argument_names})"
  end
end


class EachReverseNode < EachNode
  def to_s
    "EachReverse(#{argument_names})"
  end

  def reversed?
    true
  end
end

