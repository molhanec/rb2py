class ExpressionNode
  def real_gen
    $pygen.paren { gen_children }
  end
end