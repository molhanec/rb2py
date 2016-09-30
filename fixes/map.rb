class MapNode < BlockFixNode

  def to_s
    "Map(#{argument_names})"
  end

  def cls
    self #TODO
  end
end
