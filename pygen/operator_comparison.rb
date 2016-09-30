class CompareNode
  def real_gen
    left.gen
    $pygen.write " #{operator} "
    right.gen
  end
end