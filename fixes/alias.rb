# Represents "alias" keyword
# class Xyz
#   alias new_name old_name
# end
class AliasNode < Node

  alias new_name first_child
  alias old_name second_child

  def initialize(ruby_node, children)
    super(ruby_node)
    assign_children children
    new_name.expect_symbol
    old_name.expect_symbol
  end

  def to_s
    "Alias(#{new_name} from #{old_name})"
  end
end
