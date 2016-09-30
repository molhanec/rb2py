class IndexNode
  def real_gen
    container.gen
    $pygen.paren '[', ']' do
      gen_children
    end
  end
end

class IndexAssignNode
  def real_gen
    container.gen
    $pygen.paren '[', ']' do
      index.gen
    end
    unless value.missing?
      # part of multiple assign
      $pygen.write " = "
      value.gen
    end
  end
end