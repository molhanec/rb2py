class ClassTargetNode
  def real_gen

    name = cls.fullname.to_s

    unless $EXTERNAL_CLASSES.values.include? name or name.include? '::' or name.include? '.'
      def_node = try_to_find_surrounding DefNode
      if def_node
        outer_class = find_surrounding ClassNode
        if outer_class.has_const_attribute? name
          $pygen.write "#{outer_class.fullname.last_part}."
        end
      end
    end

    $pygen.write $pygen.py_class_name(name)
  end
end


class UnknownClassNode
  def real_gen
    $pygen.write $pygen.py_class_name(fullname.to_s)
  end
end


class Fullname
  def gen
    $pygen.write $pygen.py_class_name(to_s)
  end
end
