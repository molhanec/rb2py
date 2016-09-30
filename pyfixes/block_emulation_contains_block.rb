class DefNode

  def contains_block_with_return?
    @contains_block_with_return || false
  end

  def contains_block_with_return=(value)
    @contains_block_with_return = value
  end
end

class BlockEmulationDefNode

  def pyfix_contains_block_with_return
    return self unless contains_block_with_return?
    current = self
    while current = current.parent
      if current.is_a? DefNode and not(current.block_emulation?)
        current.contains_block_with_return = true
        break
      end
    end
    stop! "Block with return not inside normal def node!" unless current
    return self
  end
end
