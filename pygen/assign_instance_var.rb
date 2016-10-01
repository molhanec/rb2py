class AssignInstanceVarNode
  def real_gen
    target.gen
    $pygen.write "._#{name}"
    # unless we are part of the multiple assignment
    unless value.missing?
      $pygen.write " = "
      value.gen
    end
  end
end