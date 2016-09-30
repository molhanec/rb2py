class OperatorBinaryNode
  def real_gen
    if operator == '-'
      $pygen.call 'difference', 'rb2py' do
        gen_children { $pygen.write ', ' }
      end
    elsif operator == '/'
      $pygen.call 'division', 'rb2py' do
        gen_children { $pygen.write ', ' }
      end
    else
      left.gen
      $pygen.write " #{operator} "
      right.gen
    end
  end
end