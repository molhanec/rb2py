class SplatNode
  def real_gen
    $pygen.write '*'
    gen_children
  end
end