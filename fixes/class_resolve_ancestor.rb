require_relative '../pyfixes/external_classes'

module ResolveAncestor

  # Shared by ClassOrModuleNode and IncludeNode
  def real_resolve_ancestor(name)
    return nil unless name

    parts = name.split('::')
    first_part = parts[0]

    # name starts with :: => go right from the top
    if first_part == ''
      cls = toplevel.contained_class_fullname parts.reverse
      if cls
        return cls.fullname
      end
    end

    # Go up through lexical namespaces
    current = self
    ancestor_fullname = parts
    while current = current.parent
      if cls = (current.contained_class_fullname ancestor_fullname)
        return cls.fullname
      end
    end

    # Known external classes
    cls = external_class name
    return (Fullname.new cls) if cls

    unless $TESTING
      stop! "Unknown ancestor >#{name}<"
    else
      return Fullname.new name
    end
  end
end


class Node

  def contained_class_simplename(name)
    filter_children ClassOrModuleNode do
      |child|
      if child.name == name
        return child
      end
    end
    filter_children ConstantInModuleNode do
      |child|
      if child.name == name and child.child.is_a? InstantiationNode and child.child.class_name == 'Struct'
        return child
      end
    end
    return nil
  end

  def contained_class_fullname(fullname)
    if cls = (contained_class_simplename fullname[0])
      if fullname.size == 1
        # We are at the end of search
        return cls
      end
      # Strip first part of fullname and continue
      return cls.contained_class_fullname fullname[1..-1]
    end
    return nil
  end
end


class ClassOrModuleNode < Node
  attr_reader :enclosed_classes

  def fix_make_enclosed_class_list
    @enclosed_classes = []
    filter_children ClassOrModuleNode do
      |class_or_module|
      @enclosed_classes += class_or_module.enclosed_classes
    end
    d "Class '#{fullname.to_s}' contains these classes: '#{enclosed_classes_to_s}'"
    return self
  end

  def enclosed_classes_to_s
    enclosed_classes.map { |fullname| fullname.to_s }.sort.join ', '
  end
end

class ClassAncestorNode < ClassOrModuleNode
  # For classes add myself to classes list. Don't do this for plain modules.
  def fix_make_enclosed_class_list
    super
    @enclosed_classes << fullname
    d "  + '#{fullname}'"
    return self
  end
end
