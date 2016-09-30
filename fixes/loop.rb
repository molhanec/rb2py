class LoopNode < BlockFixNode

  def to_s
    "Loop"
  end

  def fix_block_calls; self end
end
