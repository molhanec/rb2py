# Modules

require_relative 'class_merge'
require_relative 'class_or_module'
require_relative 'fullname'


class Node
  def fix_module
    return self unless symbol? 'module'
    name = first_child.load_name
    children = @children[1..-1] # first child is a name

    # Modules inside class are converted to classes
    unless inside_class? or $HINTS_MODULE.include? name
      return ModuleOrPackageNode.new ruby_node, name, children
    else
      return self
    end
  end

  # It is recursively called on children so this method must be inside Node class and not
  # just inside ModuleOrPackageNode class.
  def contains_other_module?
    children.any? do |child|
      child.is_a? ModuleOrPackageNode or child.contains_other_module?
    end
  end


  # It is recursively called on children so this method must be inside Node class and not
  # just inside ModuleOrPackageNode class.
  def inside_class?
    parent = self
    while parent = parent.parent
      if parent.symbol? 'class'
        return true
      end
    end
    return false
  end
end


class ModuleOrPackageNode < ClassOrModuleNode

  attr_reader :name

  def initialize(ruby_node, name, children)
    super()
    @ruby_node = ruby_node
    @name = name
    if children.size == 1 and children[0].symbol? 'begin'
      children = children[0].children
    end
    assign_children children
  end

  def fix_global_imports
    parent = self
    while parent = parent.parent
      if parent.symbol? 'begin'
        for child in parent.children
          if require? child
            d "Global import #{child}"
            my_require = child.deep_copy
            children << my_require
            my_require.parent = self
          end
        end
      end
    end
    return self
  end

  attr_reader :fullname
  def fix_resolve_fullname
    current = self
    @fullname = Fullname.new name
    while current = current.parent
      case current
        when ModuleOrPackageNode
          fullname.prepend current.name
        when ClassAncestorNode
          stop! 'Module inside class'
      end
    end
    return self
  end

  def to_s
    "ModuleOrPackage(#{fullname})"
  end

  include ClassMerge
end


# Helper for translating plain scripts
class MainScriptModuleNode < ModuleOrPackageNode
  def initialize(child)
    super nil, 'main', [child]
  end
end
