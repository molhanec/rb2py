# Range inside index operator convert to slice

class RangeNode

  def pyfix_range_to_slice

    if parent.is_a? IndexAncestorNode
      return PythonSliceNode.new ruby_node, inclusive?, [from, to]
    end

    return self
  end
end


class PythonSliceNode < Node

  alias from first_child
  alias to second_child

  attr_reader :inclusive

  def initialize(ruby_node, inclusive, children)
    super(ruby_node)
    assign_children children
    expect_len 2
    @inclusive = inclusive
  end

  def to_s
    'PythonSlice'
  end

  def real_gen
    from.gen
    $pygen.write ':'
    if inclusive
      # [a..-1] convert to [a:]
      unless to.is_a? IntNode and to.child.value == "-1"
        $pygen.paren do
          $pygen.write '1 + '
          to.gen
        end
      end
    else
      to.gen
    end
  end
end
