require_relative 'class_resolve_ancestor'

class IncludeNode < Node

  attr_accessor :class_name
  attr_accessor :fullname
  alias name class_name

  def initialize(ruby_node, class_name)
    super(ruby_node)
    @class_name = class_name
  end

  def to_s
    "Include(#{class_name})"
  end

  include ResolveAncestor
  def fix_resolve_ancestor
    @fullname = real_resolve_ancestor class_name
    d "Ancestor '#{class_name}' of include in '#{(find_surrounding ClassNode).fullname}' resolved as '#{fullname}'"
    return self
  end
end
