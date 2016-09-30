class OperatorAppendNode
  def real_gen
    $pygen.call 'rb2py.append' do
      gen_children { $pygen.write ', ' }
    end
  end
end