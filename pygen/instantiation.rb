class InstantiationNode
  def real_gen
    $pygen.call($pygen.py_class_name(fullname.to_s)) {
      gen_children { $pygen.write ', ' }
    }
  end
end


class InstantiationFromExpressionNode
  def real_gen
    target_expression.gen
    $pygen.paren {
      $pygen.gen_comma_separated_list arguments
    }
  end
end


class EmptyClassNode
  def real_gen
    ancestor = @ancestor || ancestor_name
    $pygen.class(class_name, ancestor) {
      $pygen.pass
    }
  end
end
