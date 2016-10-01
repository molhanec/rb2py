class AssignInstanceAttrNode
  def real_gen
    unless value.missing?
      if attribute.static?
        gen_static
      else
        $pygen.call((make_setter_name name), target){
          value.gen
        }
      end
    else
      # Multiple assignment
      target.gen
      $pygen.write "._#{name}_setter"
    end
  end

  def gen_static
    target.expect_class SelfNode
    outer = find_surrounding DefNode, ClassNode
    if outer.is_a? DefNode
      cls = find_surrounding ClassNode
      $pygen.write "#{cls.name}."
    end
    $pygen.write "_#{name} = "
    value.gen
  end
end
