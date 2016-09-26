# Python ternary operator
# Ruby/C:
#   condition ? when_true : when_false
# Python:
#   when_true if condition else when_false

class IfNode

  def pyfix_ternary
    # Inside array or hash definition, inside parens, as an argument when calling method turn if statement into ternary
    if parent.is_a? PairNode or parent.is_a? BeginNode or parent.is_a? SendNode or parent.is_a? ArrayNode and when_false.children.size == 1
      # These are StatementLists
      when_true.expect_len 1
      when_false.expect_len 1
      return PythonTernary.new [condition, when_true.child, when_false.child]
    end
    return self
  end
end


class PythonTernary < Node

  alias :condition :first_child
  alias :when_true :second_child
  alias :when_false :third_child

  def initialize(children)
    super(nil)
    assign_children children
  end

  # when_true if ruby_true(condition) else when_false
  def real_gen
    $pygen.paren do
      when_true.gen
      $pygen.write ' if '
      $pygen.call('ruby_true', 'rb2py') {
        condition.gen
      }
      $pygen.write ' else '
      when_false.gen
    end
  end

  def get_result
    self
  end

  def to_s
    "PythonTernary"
  end
end
