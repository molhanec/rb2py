class FindNode < BlockFixNode

  def to_s
    "Find(#{argument_names})"
  end

  def cls
    self
  end
end
