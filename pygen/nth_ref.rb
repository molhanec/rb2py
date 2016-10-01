class RegexNthCaptureNode
  def real_gen
    $pygen.write "rb2py_regexp_captures["
    gen_children
    $pygen.write "]"
  end
end