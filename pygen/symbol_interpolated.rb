# Symbol from strings interleaved with expressions.
#   :"sym #{xyz} bol"

class SymbolInterpolatedNode
  def real_gen
    $pygen.call('to_sym0', 'rb2py') {
      first = true
      for child in children

        # Add + between expressions
        $pygen.write ' + ' unless first
        first = false

        # wrap inside rb2py.String instantiation unless it is a known string
        unless child.is_a?(StringNode)
          $pygen.write 'rb2py.String'
        end

        # generate one expression
        $pygen.paren {child.gen}
      end
    }
  end
end
