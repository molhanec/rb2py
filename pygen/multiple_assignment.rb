class MultipleAssignmentNode
  def real_gen
    lefts.gen
    $pygen.write ' = '
    rights.gen
  end
end


class MultipleAssignmentLeftHandSideNode
  def real_gen
    $pygen.paren do
      gen_children { $pygen.write ', ' }
    end
  end
end