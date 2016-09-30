class HashBlockNode < BlockFixNode

  def to_s
    "HashBlock(#{argument_names})"
  end

  def cls
    self
  end
end
