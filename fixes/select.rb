class SelectNode < BlockFixNode

  def to_s
    "Select(#{argument_names})"
  end

  def cls
    self
  end
end
