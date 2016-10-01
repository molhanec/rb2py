class RequireNode
  def real_gen
    $HINTS_IMPORTS ||= {}
    new_name = $HINTS_IMPORTS[name]
    if new_name
      $pygen.plain_import new_name unless new_name == :remove
    else
      $pygen.rb2py_import name
    end
  end
end
