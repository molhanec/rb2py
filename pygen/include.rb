class IncludeNode
  def real_gen
    $pygen.write $pygen.py_class_name(fullname.to_s)
  end
end