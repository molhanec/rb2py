# Static or module method (aka function)

class Node
  def fix_defs
    return self unless symbol? 'defs'
    expect_len 4 # target, name, argument list, body (single or inside "begin")
    target = first_child
    name = second_child.load_name
    arguments = third_child
    body = fourth_child.make_statement_list
    return DefSingletonNode.new @ruby_node, target, name, arguments, body
  end
end


class DefSingletonNode < NoInitializeDefNode

  alias target fourth_child

  def initialize(ruby_node, target, name, arguments, body)
    super(ruby_node, name, arguments, body)
    @true_method = false
    children << target
    target.parent = self
  end

  def to_s
    "DefSingleton(#@name)"
  end

  # Transform normal method in static method
  def self.from_def(def_node)
    DefSingletonNode.new def_node.ruby_node, (SelfNode.new def_node.ruby_node), def_node.new_name, def_node.arguments, def_node.body
  end
end
