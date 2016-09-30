class DetectNode < BlockFixNode

  def to_s
    "Detect(#{argument_names})"
  end

  def cls
    self
  end
end
