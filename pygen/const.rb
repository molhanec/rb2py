require_relative '../pyfixes/external_classes'

class ConstantNode

  def real_gen

    # We expect that names in $EXTERNAL_CLASSES array or names which include namespace separators
    # are already fully qualified, so we don't want them to prefix.
    unless $EXTERNAL_CLASSES.values.include? name.to_s or name.to_s.include? '::' or name.to_s.include? '.'
      current = self
      # If we are in a method then prefix constant with "self."
      while current = current.parent
        if current.is_a? DefNode
          $pygen.write "self."
          break
        end
      end
    end

    $pygen.write $pygen.py_class_name(name.to_s)
  end
end


# This is definition, so it is basically an assignment
class ConstantInModuleNode

  def real_gen
    $pygen.indent

    current = self
    # If we are in a method then prefix constant with "self."
    while current = current.parent
      if current.is_a? DefNode
        $pygen.write "self."
        break
      end
    end

    $pygen.write $pygen.py_class_name(name)
    $pygen.write ' = '
    gen_children
  end

  def fullname
    parent.fullname + name
  end
end
