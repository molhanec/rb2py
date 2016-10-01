class AssignClassVarNode
  def real_gen
    parent = self
    while parent = parent.parent
      if parent.is_a? DefNode
        cls = find_surrounding ClassNode
        $pygen.write "#{cls.name}."
        break
      end
    end
    $pygen.write "_#{name}"
    # unless we are part of the multiple assignment
    unless value.missing?
      $pygen.write " = "
      value.gen
    end
  end
end
