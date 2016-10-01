# In Ruby, instantiation is done by sending "new" message to an expression returning class, typically a constant which
# represents class.
class Node

  def make_instantiation
    expect_min_len 2
    # First child is a target (class name or an expression)
    # Second child is a "new" string
    arguments = children[2..-1]

    begin
      class_name = first_child.load_name
    rescue
      # There is not class name hardcoded, but instead it is an expression
      return InstantiationFromExpressionNode.new @ruby_node, first_child, arguments
    end

    if class_name == 'Class'
      # Special case:
      #   Creating instances of the Ruby's Class class is
      #   is a way to create empty classes (used e.g. for Exceptions)
      expect_len 3
      ancestor_name = third_child.load_name
      return EmptyClassNode.new @ruby_node, ancestor_name
    end

    # Standard instantiation
    return InstantiationNode.new @ruby_node, class_name, arguments
  end

  def make_self_instantiation
    expect_min_len 2
    cls = find_surrounding ClassAncestorNode
    return InstantiationNode.new @ruby_node, cls.name, @children[2..-1]
  end
end


# ClassName.new(arguments)
class InstantiationNode < Node

  attr_reader :fullname, :class_name
  attr_reader :target

  def initialize(ruby_node, class_name, children)
    super()
    @ruby_node = ruby_node
    @class_name = class_name
    assign_children children
    @target = make_global_target
  end

  def to_s
    "Instantiation(#{class_name})"
  end

  def argument_count
    return children.size
  end
end


# expression_returning_class.new(arguments)
class InstantiationFromExpressionNode < Node

  def target_expression
    first_child
  end

  def arguments
    children[1..-1]
  end

  def argument_count
    return children.size - 1
  end

  def initialize(ruby_node, expression, arguments)
    super(ruby_node)
    assign_children [expression, *arguments]
  end

  def to_s
    "InstantiationFromExpression"
  end

  def cls
    self
  end
end


# NewEmptyClass = Class.new(AncestorClass)
class EmptyClassNode < ClassAncestorNode

  attr_accessor :ancestor, :ancestor_name, :class_name

  def initialize(ruby_node, ancestor_name)
    super()
    @ruby_node = ruby_node
    @ancestor = nil
    @ancestor_name = ancestor_name
  end

  def to_s
    "EmptyClass(#{class_name} extends #{ancestor_name})"
  end

  alias fix try_run_fixture
end
