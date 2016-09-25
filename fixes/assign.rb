# Assignments

require_relative 'subexpression'

# Just marker for all assignments
class AssignGenericNode < SubexpressionNode; end

class AssignNode < AssignGenericNode

  attr_reader :name

  def initialize(ruby_node, target, name, value)
    super ruby_node
    @name = name
    assign_children [target, value]
  end

  alias target first_child
  alias value second_child
  def value=(new_value)
    children[1] = new_value
    new_value.parent = self
  end

  def to_s
    "Assign(#{name})"
  end

  def real_gen
    stop! "Assign is abstract #{self}"
  end
end


class AssignInstanceNode < AssignNode

  attr_reader :attribute

  def fix_attribute
    cls = find_surrounding ClassOrModuleNode
    attribute = cls.find_attribute name
    attribute = cls.find_static_attribute name unless attribute
    attribute = cls.add_attribute(ruby_node, name) unless attribute
    attribute.cls = value.cls
    @attribute = attribute
    return self
  end
end


class AssignInstanceAttrNode < AssignInstanceNode
  def to_s
    "AssignInstanceAttr(#{@name})"
  end
end


class AssignLocalVarNode < AssignNode

  def initialize(ruby_node, children)
    name = children[0].load_name
    value = case children.size
              when 1 then MissingNode.new self, ruby_node
              when 2 then children[1]
              else stop! 'Expected 1 or 2 children'
            end
    super ruby_node, SelfNode.new(ruby_node), name, value
  end

  def to_s
    "AssignLocalVar(#{name})"
  end

  def fix_local_assignment
    @cls = value.cls
    return self
  end

  def cls; self; end

  def getter
    LocalVariableNode.new ruby_node, [(NewValueNode.new ruby_node, name)]
  end
end


class MultipleAssignmentNode < AssignGenericNode

  alias lefts first_child
  alias rights second_child
  alias rights= second_child=

  def initialize(ruby_node, children)
    super ruby_node
    lefts = children[0]
    lefts.expect 'mlhs'
    assign_children children
  end

  def to_s
    "MultipleAssignmentNode(#{name})"
  end

  def fix_local_assignment
    self
  end
end
