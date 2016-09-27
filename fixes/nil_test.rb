# Represents
#   expression.nil?

class NilTestNode < Node

  alias target child

  def initialize(ruby_node, target)
    super(ruby_node)
    assign_children [target]
  end
end