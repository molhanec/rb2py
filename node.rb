# Common ancestor for all AST nodes

class Node

  attr_accessor :already_generated,
                :parent

  attr_reader :children,
              :name,
              :ruby_node

  def initialize(parent=nil, ruby_node=nil)
    @already_generated = false
    @parent = parent
    @ruby_node = ruby_node
    @children = []
  end

  def initialize_copy(other)
    super
    @already_generated = false
  end

  def deep_copy_children
    new_children = []
    for child in children
      new_children << child.deep_copy
    end
    assign_children new_children
  end

  def deep_copy
    new_obj = clone
    new_obj.deep_copy_children
    new_obj
  end
  
  def to_s_recursive
    name = to_s.strip

    if children.empty?
      indent_str + name
    else
      s = "#{indent_str}+#{name}\n"
      $indent += 1
      s += @children.collect { |c| c.to_s_recursive + "\n" }.join
      $indent -= 1
      return s.rstrip
    end
  end

  def to_s
    "#{(@ruby_node.is_a? AST::Node) ? @ruby_node.type : @ruby_node}"
  end

  def inspect
    to_s
  end

  def ruby_node_to_s
    @ruby_node.type.to_s
  end

  def real_gen
    msg = "Unimplemented real_gen() for\n#{self.inspect}\nParent: #{parent}"
    if $require_implemented_gen
      stop! msg
    else
      d "Unimplemented real_gen() for\n#{self.inspect}"
      parent = self
      while parent = parent.parent
        d "  #{parent}"
      end
    end
  end

  def gen(&block)
    unless @already_generated
      real_gen &block
      @already_generated = true
    end
  end

  def expect(what)
    if @ruby_node.type.to_s != what
      stop! "Expected #{what}, but found #@ruby_node"
    end
  end

  def expect_class(cls, msg='')
    unless is_a? cls
      fail "Expected class #{cls}, but found #{self}. #{msg}"
    end
  end

  def expect_missing
    stop! 'nil expected'
  end

  def expect_symbol
    stop! 'Symbol expected'
  end

  # Allows ranges
  def expect_len(len, children=nil, msg:nil)
    children = @children if children.nil?
    if children.nil?
      stop! "No children for #{self}", additional_msg:msg
    end
    unless len === children.size
      stop! "Expected length #{len}, but found #{children.size}", bt: caller, additional_msg:msg
    end
  end

  def expect_min_len(len, msg:nil)
    if @children.size < len
      stop! "Expected minimal length #{len}, but found #{@children.size}", bt: caller, additional_msg:msg
    end
  end

  def child(index=0)
    expect_min_len index + 1
    children[index]
  end

  def set_child(index=0, value)
    expect_min_len index + 1
    children[index] = value
    value.parent = self
  end

  def first_child; child; end
  def first_child=(value); set_child value; end

  def second_child; child(1); end
  def second_child=(value); set_child 1, value; end

  def third_child; child(2); end
  def third_child=(value); set_child 2, value; end

  def fourth_child; child(3); end
  def fourth_child=(value); set_child 3, value; end

  def last_child
    expect_min_len 1
    children[-1]
  end

  def last_child=(value)
    expect_min_len 1
    children[-1] = value
    value.parent = self
  end

  def assign_children(children)
    @children = children
    children.each do
      |child|
      if child.nil?
        stop! 'There should be no nil between children'
      end
      child.parent = self
    end
  end

  def add_child(child)
    child.parent = self
    children << child
    return child
  end

  def prepend_child(child)
    child.parent = self
    children.unshift child
    return child
  end

  def add_children(children)
    for child in children
      add_child child
    end
  end

  def fix(fixture)

    if @children.nil?
      fail "You should not call fix on #{self}, I don't have children."
    end

    unless RUBY_PLATFORM == "java"
      new_children = @children.collect do
        |child|
        child = child.fix fixture
        child
      end
    else
      # jruby-9.1.2.0 bug? work-around
      new_children = []
      for child in children
        new_children << (child.fix fixture)
      end
    end

    # Child might return more than one value.
    # E.g. one attr_reader Node with two names will
    # be expanded into two separate AttributeNode nodes.
    assign_children new_children.flatten

    # Run fixture on self and return it.
    return (try_run_fixture fixture)
  end

  # Run fixture on self and return it.
  # Note that some fixtures might be implemented
  # only for specific descendants, thus the condition.
  def try_run_fixture(fixture)
    if respond_to? fixture
      $single_fix_was_run += 1
      d "Fixing #{fixture} for #{self.class.name}, object: #{object_id}" if $fixture_trace
      method(fixture).call
    else
      self
    end
  end

  def load_name
    if symbol? 'sym'
      expect_len 1
      return child.ruby_node_to_s
    elsif is_a? SymbolNode
      return value
    elsif symbol? 'cbase'
      return 'rb2py'
    else
      expect 'const'
      expect_len 2

      parent_name = first_child.load_name

      second_child.expect_symbol
      my_name = second_child.ruby_node_to_s

      if parent_name
        return "#{parent_name}::#{my_name}"
      else
        return my_name
      end
    end
  end

  def symbol?(*names)
    false
  end

  def children_of_class?(cls)
    children.any? do
      |child|
      child.is_a? cls
    end
  end

  def filter_children(cls, &block)
    filtered = @children.select do
      |child|
      child.is_a? cls
    end
    filtered.each(&block) if block_given?
    filtered
  end

  def filter_recursive(children, cls, &block)
    filtered = []
    for child in children
      if child.is_a? cls
        yield child if block_given?
        filtered << child
      end
      filtered += filter_recursive child.children, cls, &block
    end
    filtered
  end

  # Applies method what, represented by symbol what_sym
  # to each children which is instance of class cls
  def apply_children(what_sym, cls)
    filter_children(cls).map(&what_sym)
  end

  def one_of_classes?(classes)
    if classes.is_a? Array
      classes.any? do
        |cls|
        is_a? cls
      end
    else
      # Single class
      is_a? classes
    end
  end

  # Calls gen on all children of class cls (if given,
  # all otherwise).
  # If there is a block, it's called between two children
  def gen_children(cls = nil)
    first = true
    for child in children
      if (cls.nil? or child.one_of_classes?(cls)) and not child.already_generated
        yield if block_given? and not first
        first = false
        child.gen
      end
    end
  end

  def missing?
    false
  end

  def try_to_find_surrounding(*node_classes)
    current = parent
    while current
      for node_class in node_classes
        return current if current.is_a? node_class
      end
      current = current.parent
    end
    return nil # not found
  end

  def find_surrounding(*node_classes)
    result = try_to_find_surrounding *node_classes
    return result if result
    stop! "(#{self}) should be inside #{node_classes.join(' or ')}", bt:caller
  end

  # Go up...
  def all(cls, &block)
    parent.all cls, &block
  end

  # ...and down :-)
  def real_all(cls, &block)
    for child in children
      child.real_all cls, &block
    end
    block.call(self) if is_a? cls
  end

  def all_classes(&block)
    all ClassAncestorNode, &block
  end

  def mark_ungenerated
    self.already_generated = false
    for child in children
      child.mark_ungenerated
    end
  end

  def cls?
    respond_to? :cls and (not cls.nil?)
  end

  def guess_each_class
    d '  guess_each_class => cls'
    if respond_to? :cls
      cls
    else
      stop! 'no cls method'
    end
  end

  def stop!(msg, title=nil, bt:caller, additional_msg:nil)
    begin
      position = ruby_node.location.name.to_s
    rescue
      position = nil
    end
    if title
      msg = "#{title}:\n#{'=' * (title.size + 5)}\n#{msg}"
    end
    if additional_msg
      msg += ". #{additional_msg}"
    end
    make_stop(msg, bt:bt, position:position)
  end

  def toplevel
    parent.toplevel
  end

  def contained_class_fullname(name)
    false
  end
  alias contained_class_simplename contained_class_fullname
end # Node


class NoChildrenNode < Node
  alias fix try_run_fixture
end


class UnprocessedNode < Node

  def initialize(parent, ruby_node)
    super()
    @parent = parent
    @ruby_node = ruby_node
    @children = []
    for child in ruby_node.children
      cls = case child
              when AST::Node then UnprocessedNode
              when NilClass then MissingNode
              when Symbol then SymbolLeafNode
              when String then StringLeafNode
              when Numeric then NumberLeafNode
              else fail "Unknown Ruby node #{child.inspect}"
            end
      new_child = cls.new self, child
      @children << new_child
    end
  end

  def cls
    d "Called cls for #{self}"
    nil
  end

  def symbol?(*names)
    if ruby_node.is_a? AST::Node and ruby_node.type.is_a? Symbol
      names.include? ruby_node.type.to_s
    elsif ruby_node.is_a? Symbol
      names.include? ruby_node.to_s
    else
      false
    end
  end
end # UnprocessedNode
