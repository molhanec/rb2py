class BlockpassNode

  def real_gen
    $pygen.write "block="
    gen_children
  end
end