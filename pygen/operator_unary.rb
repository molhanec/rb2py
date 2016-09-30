class OperatorUnaryNode
  def real_gen
    $pygen.write operator
    value.gen
  end
end