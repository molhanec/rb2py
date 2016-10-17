# Instance and class level attributes


require_relative 'node_with_class.rb'
class Node

  def make_attribute(require_getter:false, require_setter:false)
    expect_min_len 3
    first_child.expect_missing
    attributes = []
    for child in children[2..-1]
      name = child.load_name
      ruby_node = child.ruby_node
      attributes << AttributeNode.new(ruby_node, name, require_getter:require_getter, require_setter:require_setter)
    end
    return attributes
  end
end


# Instance level attribute
class AttributeNode < NoChildrenNode

  include NodeWithClass

  attr_reader :name, :require_getter, :require_setter

  def initialize(ruby_node, name, require_getter:false, require_setter:false)
    super()
    @ruby_node = ruby_node
    @name = name
    @require_getter = require_getter
    @require_setter = require_setter
  end

  def to_s
    "Attribute(#@name of class #{class_name})"
  end

  def static?
    false
  end
end


# Class level attribute
class AttributeStaticNode < NoChildrenNode

  include NodeWithClass

  attr_reader :name

  def initialize(ruby_node, name)
    super()
    @ruby_node = ruby_node
    @name = name
  end

  def self.from_attribute(attribute)
    new attribute.ruby_node, attribute.name
  end

  def to_s
    "AttributeStatic(#@name of class #{class_name})"
  end

  def static?
    true
  end
end
