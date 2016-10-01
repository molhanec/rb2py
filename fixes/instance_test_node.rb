class InstanceTestNode < Node

  attr_accessor :cls, :class_name
  alias target first_child

  def initialize(ruby_node, children)
    super()
    @ruby_node = ruby_node
    assign_children children
    @class_name = second_child.load_name
  end

  def to_s
    'InstanceTestNode'
  end

  require_relative 'instantiation_fullname'
  include InstantiationFullname
end
