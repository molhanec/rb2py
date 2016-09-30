class DeleteIfNode < BlockFixNode

  def to_s
    "DeleteIf(#{argument_names})"
  end

  def cls
    self
  end
end
