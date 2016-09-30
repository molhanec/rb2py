class PartitionNode < BlockFixNode

  def to_s
    "Partition(#{argument_names})"
  end

  def cls
    self
  end
end
