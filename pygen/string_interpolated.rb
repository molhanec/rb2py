# String interleaved with expressions.
# Generate as series of expressions concated using + operator.

class StringInterpolatedNode

  def real_gen
    first = true
    for child in children

      # add + between expressions
      $pygen.write ' + ' unless first
      first = false

      # wrap inside String() instantiation unless it is already a String
      unless child.is_a?(StringNode)
        $pygen.write 'rb2py.String'
      end

      # generate one expression
      $pygen.paren { child.gen }
    end
  end
end
