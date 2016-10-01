require_relative 'class_merge'
require_relative 'class_or_module'
require_relative 'class_resolve_ancestor'
require_relative 'fullname'
require_relative 'late_inserter'


class Node
  def fix_class
    return self unless symbol? 'class' or symbol? 'module'
    if symbol? 'class'
      expect_len 3
      ancestor_name = (second_child.is_a? MissingNode) ? nil : second_child.load_name
      body = third_child
    else
      expect_len 2
      ancestor_name = nil
      body = second_child
    end
    class_name = first_child.load_name
    if body.missing?
      cls_node = EmptyClassNode.new ruby_node, ancestor_name
      cls_node.class_name = class_name
      return cls_node
    else
      # If body contains more statements, they will be wrapped inside 'begin' node.
      if body.symbol? 'begin'
        body = body.children
      else
        # Single body statement wrap inside an array.
        body = [body]
      end
    end
    return ClassNode.new @ruby_node, class_name, ancestor_name, body
  end

  def has_attribute?(name)
    false # Only classes can have attributes
  end
  alias has_method? has_attribute?
end


# Also for EmptyClassNode
class ClassAncestorNode < ClassOrModuleNode

  attr_reader :ancestor, :ancestor_name
  attr_accessor :fullname

  def fix_resolve_fullname
    current = self
    @fullname = Fullname.new name
    while current = current.parent
      if current.is_a? ClassAncestorNode or current.is_a? ModuleOrPackageNode
        fullname.prepend current.name
      end
    end
    return self
  end

  include ResolveAncestor
  def fix_resolve_ancestor
    return self if ancestor_name == ''
    @ancestor = real_resolve_ancestor ancestor_name
    d "Ancestor '#{ancestor_name}' of class '#{fullname}' resolved as '#{ancestor_name_to_s}'"
    return self
  end

  def ancestor_name_to_s
    ancestor.to_s
  end
end


class ClassNode < ClassAncestorNode

  include LateInserter

  attr_accessor :calls_super_initialize
  attr_accessor :class_name
  alias name class_name
  alias name= class_name=

  def initialize(ruby_node, class_name, ancestor_name, children)
    super()
    @ruby_node = ruby_node
    @class_name = class_name
    @ancestor_name = ancestor_name
    @calls_super_initialize = false
    assign_children children
  end

  def to_s
    ancestor_str = ancestor_name != '' ? " extends #{ancestor_name}" : ''
    "Class(#{fullname}#{ancestor_str})"
  end

  include ClassMerge

  def local_variable?(var_name, search_parent_defs:false)
    false
  end
end
