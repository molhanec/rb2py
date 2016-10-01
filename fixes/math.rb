class UnprocessedNode
  def make_math_call
    function_name = second_child.load_name
    arguments = children[2..-1] # 0 is 'Math', 1 is function name
    MathNode.new ruby_node, function_name, arguments
  end
end

class MathNode < Node

  attr_reader :function_name

  def initialize(ruby_node, function_name, arguments)
    super(ruby_node)
    @function_name = function_name
    assign_children arguments
  end

  def to_s
    "Math(#{function_name})"
  end

  def cls
    self
  end
end
