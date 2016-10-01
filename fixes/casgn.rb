# Assignment to constant

require_relative 'fullname'

class UnprocessedNode

  def fix_casgn
    return self unless symbol? 'casgn'
    expect_len 3
    object_name = second_child.ruby_node_to_s
    value_node = third_child
    if first_child.is_a? MissingNode
      # Global names have nil as a target object.
      # In Ruby, global items are added to the Object class.
      return fix_global_casgn object_name, value_node
    end
    parent_name = first_child.load_name
    all_classes {
      |cls|
      if cls.fullname.to_s == parent_name
        cls.add_child ConstantInModuleNode.new ruby_node, object_name, value_node
        return []
      end
    }
    stop! "Cannot find parent '#{parent_name}' for #{object_name}"
  end

  def fix_global_casgn(object_name, value_node)
    if value_node.is_a? EmptyClassNode
      # Special case: it's an empty class declaration
      value_node.class_name = object_name
      return value_node
    end

    ConstantInModuleNode.new ruby_node, object_name, value_node
  end
end


class ConstantInModuleNode < Node

  # attr_reader :fullname
  alias value child

  def initialize(ruby_node, name, value)
    super(ruby_node)
    @name = name
    assign_children [value]
  end

  def to_s
    "ConstantInModule(#{name})"
  end
end
