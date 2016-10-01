class EnsureNode
  def real_gen
    $pygen.write 'try:'
    $pygen.indented do
      protected.gen
    end
    $pygen.indent 'finally:'
    $pygen.indented do
      ensured.gen
    end
  end
end


class RescueNode
  def real_gen
    $pygen.write 'try:'
    $pygen.indented do
      protected.gen
    end
    rescued.gen
  end
end


class RescueBodyNode
  def real_gen
    $pygen.indent 'except '
    unless exception_class.missing? and exception_variable.missing?
      unless exception_class.missing?
        exception_class.gen
      else
        $pygen.write 'Exception' # all standard exceptions
      end
      unless exception_variable.missing?
        $pygen.write ' as '
        exception_variable.gen
      end
    end
    $pygen.write ':'
    $pygen.indented do
      statements.gen
    end
  end
end
