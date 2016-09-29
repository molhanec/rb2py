class YieldNode
  def real_gen
    $pygen.write 'yield '
    gen_children { $pygen.write ', ' }
  end
end