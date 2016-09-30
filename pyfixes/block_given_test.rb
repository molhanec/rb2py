class BlockGivenTestNode

  attr_accessor :block_arg

  def pyfix_block_given_test
    fun = find_surrounding NoInitializeDefNode
    fun.block_given_test = true
    self.block_arg = fun.block_argument
    return self
  end
end