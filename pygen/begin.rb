class BeginNode
  def real_gen
    $pygen.paren { gen_children }
  end
end