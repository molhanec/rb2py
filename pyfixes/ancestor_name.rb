class ClassAncestorNode

  # If ancestor's name starts with topmost module, remove it
  def pyfix_ancestor_name
    if ancestor and ancestor_name.include? '::'
      first_part, *rest = ancestor_name.split '::'
      topmost_module = find_topmost_module
      if topmost_module.name == first_part
        @ancestor_name = rest.join '::'
      end
    end
    return self
  end

  # Finds topmost module in which is this class contained
  def find_topmost_module
    current = self
    topmost_module = nil
    while current = current.parent
      if current.is_a? ModuleOrPackageNode
        topmost_module = current
      end
    end
    return topmost_module
  end
end
