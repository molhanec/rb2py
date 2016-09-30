class MapInPlaceNode < BlockFixNode

  def to_s
    "MapInPlace(#{argument_names})"
  end

  def cls
    self
  end
end
