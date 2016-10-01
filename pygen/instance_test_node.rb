class InstanceTestNode
  def real_gen
    if cls
      class_name = cls.fullname.to_s
    else
      # for instance test nodes created in pyfix\case.rb
      class_name = second_child.load_name
    end
    case class_name
      when 'NilClass'
        target.gen; $pygen.write ' is None'
      when 'TrueClass'
        $pygen.call_isinstance do
          target.gen
          $pygen.write ', '
          $pygen.write 'bool'
        end
        $pygen.write ' and '
        target.mark_ungenerated
        target.gen
      when 'FalseClass'
        $pygen.call_isinstance do
          target.gen
          $pygen.write ', '
          $pygen.write 'bool'
        end
        $pygen.write ' and not'
        $pygen.paren do
          target.mark_ungenerated
          target.gen
        end
      when 'String'
        $pygen.write 'rb2py.is_string'
        $pygen.paren { target.gen }
      when 'Proc'
        $pygen.write 'callable'
        $pygen.paren { target.gen }
      else
        $pygen.call_isinstance do
          target.gen
          $pygen.write ', '
          $pygen.write $pygen.py_class_name class_name
        end
    end
  end
end
