# Logical and/or operators.
#
#   a() and/or b()
# ==>
#   ruby_true(a()) and/or ruby_true(b())
#
# This works only when we are not interested in the value per se, only true/false result.
# For cases when value is important see pyfixes/and_or.rb

class AndNode
  def real_gen
    $pygen.call('ruby_true', 'rb2py') {
      first_child.gen
    }
    $pygen.write ' and '
    $pygen.call('ruby_true', 'rb2py') {
      second_child.gen
    }
  end
end

class OrNode
  def real_gen

    # Normally there would be only two children of OrNode, however WhenNode can be converted into OrNode with multiple
    # children. See WhenNode#pyfix_case

    first = true
    for child in children
      unless first
        $pygen.write ' or '
      else
        first = false
      end
      $pygen.call('ruby_true', 'rb2py') {
        child.gen
      }
    end
  end
end