# Shared properties of classes and modules

class ClassOrModuleNode < Node

  def defs
    filter_children DefNode
  end

  def attributes
    filter_children AttributeNode
  end

  def static_attributes
    filter_children AttributeStaticNode
  end

  def const_attributes
    filter_children ConstantInModuleNode
  end

  def has_attribute?(name)
    not find_attribute(name).nil?
  end

  def has_static_attribute?(name)
    not find_static_attribute(name).nil?
  end

  def has_const_attribute?(name)
    not find_const_attribute(name).nil?
  end

  def find_attribute(name)
    attributes.find {
      |attribute|
      attribute.name == name
    }
  end

  def find_static_attribute(name)
    static_attributes.find {
      |attribute|
      attribute.name == name
    }
  end

  def find_const_attribute(name)
    const_attributes.find {
      |attribute|
      attribute.name == name
    }
  end

  def add_attribute(ruby_node, name)
    attribute = AttributeNode.new ruby_node, name
    add_child attribute
    return attribute
  end

  def add_static_attribute(ruby_node, name)
    attribute = AttributeStaticNode.new ruby_node, name
    add_child attribute
    return attribute
  end

  def has_method?(name)
    not find_method(name).nil?
  end

  # Note that this uses cached results, so it generally unsafe during tree modifications.
  def has_or_inherits_method?(name)
    return true if has_method? name
    for ancestor_class in ancestors_classes!
      return true if ancestor_class.has_or_inherits_method? name
    end
    return false
  end

  def find_method(name)
    found = defs.find {
      |method|
      method.new_name == name
    }
    unless found
      filter_children(AliasNode) {
        |method|
        if method.new_fixed_name == name
          found = method
          break
        end
      }
    end
    return found
  end

  # original fullname before flattening/renaming
  def original_fullname
    @original_fullname or fullname
  end
  def save_original_fullname
    @original_fullname = fullname
  end

  private

  # Note that this will cache the result, so it generally unsafe during tree modifications.
  def ancestors_fullnames!
    @ancestors_fullnames ||= begin
      result = []
      result << ancestor if ancestor
      filter_children(IncludeNode) {
          |include_node|
        result << include_node.fullname if include_node.fullname
      }
      result
    end
  end

  # Note that this will cache the result, so it generally unsafe during tree modifications.
  def ancestors_classes!
    @ancestors_classes ||= begin
      fullnames = ancestors_fullnames!
      result = []
      all_classes {
          |cls|
        if cls.fullname and fullnames.include? cls.fullname
          result << cls
        end
      }
      result
    end
  end
end
