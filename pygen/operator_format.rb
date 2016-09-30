class OperatorFormatNode
  def real_gen
    format_string.gen
    $pygen.write ' % '
    $pygen.paren { gen_children }
  end
end