class AttributeStaticNode

  def real_gen
    $pygen.binop "_#{name}", '=', 'None'
  end
end