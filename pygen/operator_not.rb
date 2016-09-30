class OperatorNotNode
  def real_gen
    $pygen.write 'not'
    $pygen.paren { gen_children }
  end
end