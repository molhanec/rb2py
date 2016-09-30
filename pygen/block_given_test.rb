class BlockGivenTestNode
  def real_gen
    if block_arg
      $pygen.write block_arg.name
    else
      stop! "block_given? test inside method without block argument!"
    end
  end
end
