class UnprocessedNode
  def make_delegates
    expect_len 3
    first_child.expect_missing
    third_child.expect_class HashNode
    hash = third_child
    hash.expect_len 1 # one pair
    pair = hash.child
    pair.expect_len 2
    array = pair.first_child
    array.expect_class ArrayNode
    target = pair.second_child
    target.expect_symbol
    result = []
    for method in array.children
      method.expect_symbol
      result << (DelegateNode.new ruby_node, method, target)
    end
    return result
  end
end


class DelegateNode < Node

  alias :delegate :first_child
  alias :target :second_child

  def initialize(ruby_node, delegate, target)
    super(ruby_node)
    assign_children [delegate, target]
  end

  def to_s
    "Delegate(#{delegate.name})"
  end
end
