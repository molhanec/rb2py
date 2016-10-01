class ClassVariableNode
  def real_gen
    cls = find_surrounding ClassNode
    $pygen.call name, cls.name
  end
end