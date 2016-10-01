class RaiseNode
  def real_gen
    $pygen.write 'raise '
    gen_children
  end
end