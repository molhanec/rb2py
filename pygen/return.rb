class ReturnNode
  def real_gen
    $pygen.write 'return '
    value.gen if children.size > 0
  end
end