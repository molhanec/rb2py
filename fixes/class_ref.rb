class Node

  require_relative 'standard_classes'
  require_relative '../fixes/class_resolve_ancestor'

  include ResolveAncestor

  def make_class_reference(fullname)

    fullname = real_resolve_ancestor fullname.to_s

    cls = get_standard_class fullname.to_s
    return cls if cls
    all_classes do |cls|
      d "  looking for #{fullname} against #{cls.fullname}"
      return cls if cls.fullname == fullname
    end
    w1 "Class not found #{fullname}"
    return UnknownClassNode.new ruby_node, fullname
  end

  def make_class_target(fullname)
    class_ref = make_class_reference(fullname)
    unless class_ref
      class_ref = UnknownClassNode.new ruby_node, fullname
    end
    return ClassTargetNode.new ruby_node, class_ref
  end
end



class ArrayNode < Node
  # tries to guess class for for-each type cycle variable
  def guess_each_class
    if children.size == 0
      d "Empty array, cannot guess type of elements #{self}"
      return nil
    end
    if child.respond_to? :cls
      d "Found class #{child.cls} for each loop #{self}"
      return child.cls
    end
    d "Cannot resolve class for each loop #{self}, child has no cls method"
    nil
  end
end


class ClassAncestorNode < ClassOrModuleNode

  def fix_class_referencexx
    unless ancestor_name.empty?
      d "Class ancestor reference #{ancestor_name}"
      @ancestor = make_class_target ancestor_name
    end
    return self
  end

  def to_s; 'ClassAncestor'; end
end



# Sometimes the class itself can be a target, not an instance
class ClassTargetNode < Node

  attr_reader :cls

  def initialize(ruby_node, cls=nil)
    super(ruby_node)
    @cls = cls if cls
  end

  def to_s
    "ClassTarget(#{cls})"
  end

  def name
    cls.name
  end
end



class InstantiationNode < Node

  attr_reader :cls

  def fix_class_reference
    d "Instantiation reference #{fullname}"
    @cls = make_class_reference fullname
    self
  end
end



class InstanceTestNode < Node

  def fix_class_reference
    expect_len 2 # target and classname
    @cls = make_class_reference fullname
    self
  end
end



require_relative 'fullname'
class UnknownClassNode < Node

  attr_reader :fullname

  def initialize(ruby_node, fullname)
    super(ruby_node)
    @fullname = Fullname.new fullname
  end

  def to_s
    "UnknownClassNode(#{fullname})"
  end

  def name
    fullname.to_s
  end
end
