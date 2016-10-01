class PrivateNode < Node

  attr_accessor :access_type

  def initialize(ruby_node, access_type)
    super(ruby_node)
    @access_type = access_type
  end

  def to_s
    "Private(#{access_type})"
  end
end
