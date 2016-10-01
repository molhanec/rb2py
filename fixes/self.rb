class Node
  def fix_self
    return self unless symbol? 'self'
    expect_len 0
    return SelfNode.new @ruby_node
  end

  def self?
    false
  end
end


class SelfNode < NoChildrenNode

  include NodeWithClass

  def initialize(ruby_node)
    super()
    @ruby_node = ruby_node
  end

  def initialize_copy(other)
    @ruby_node = other.ruby_node
  end

  def to_s
    "Self"
  end

  def self?
    true
  end

  def fix_resolve_self
    @cls = find_surrounding ClassNode, ModuleOrPackageNode
    self
  end

  def has_attribute?(name)
    fix_resolve_self unless cls
    cls.has_attribute? name
  end

  def has_method?(name)
    fix_resolve_self unless cls
    cls.has_method? name
  end
end
