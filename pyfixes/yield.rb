# Make block argument explicit.
# Handle situation when the yield is inside block.
#   def a
#     m { yield }
#   end
# ==>
#   def a(self, block=rb2py.NO_BLOCK):
#     def __block_XXX():
#       nonlocal block
#       block()
#
# Yield is kept only inside each method definition (which is translated to __iter__)

class DefNode
  def iteration_node?
    name == "each"
  end
end

class YieldNode
  def pyfix_yield
    current = self
    block_emulations = []
    while current = current.parent
      if current.is_a? DefNode
        return self if current.iteration_node? # becames __iter__, keep yield
        break if current.block_argument # we can stop searching when there is an explicit block argument
        if current.block_emulation?
          # Don't add it to nonlocals immediately, in a case that the emulation block is inside __iter__.
          # E.g. keep yield in situations like:
          #   def __iter__(self):
          #     def _block_XXX():
          #       yield
          #     _block_XXX()
          block_emulations << current
        else
          current.arguments.add_child BlockArgumentNode.new self, [NewValueNode.new(self, 'block')]
          break
        end
      end
    end

    for block_emulation in block_emulations
      block_emulation.nonlocals << 'block'
    end

    return make_global_call 'block', *children
  end
end
