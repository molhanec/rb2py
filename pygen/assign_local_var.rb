class AssignLocalVarNode
  def real_gen
    $pygen.write name
    # unless we are part of the multiple assignment
    unless value.missing?
      $pygen.write " = "
      value.gen
    end
  end
end