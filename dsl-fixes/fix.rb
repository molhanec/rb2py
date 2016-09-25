# This serves as a simple internal DSL for the simplest transformations (a.k.a fixes).
# This is used for the input transformations where unprocessed nodes are transformed into concrete nodes based mostly
# on their symbol. The symbol is typically extracted from name (see gen_expected_symbol method), or it can be specified
# explicitly using the expected_symbol method.
#
# Usage is described in the simple_fixes.rb
class Fix; end
class << Fix

  attr_accessor :aliases,
                :class_name,
                :class_target,
                :named,
                :node_class,
                :expected_len,
                :expected_symbol

  def inherited(cls)
    cls.aliases = []
    cls.class_name = nil
    cls.class_target = false
    cls.named = false
    cls.node_class = nil
    cls.expected_len = nil
    cls.expected_symbol = nil
    super
    $dsl_fixes << cls
  end

  # Aliases for children nodes of the resulting node class
  Alias = Struct.new(:new_name, :old_name)
  def alias_child(new_name, old_name = :child)
    aliases << Alias.new(new_name, old_name)
  end

  # Name of the generated class as a symbol. "Node" will be added automatically to the class name
  def class_name(name)
    @class_name = name
  end

  # This will generated cls method used for simple static analysis
  def class_target
    @class_target = true
  end

  # If specified, it will check if there is correct number of subnodes
  def expect_len(len)
    @expected_len = len
  end

  # It will generate "name" and "load_name" methods which will delegate the call to the first child
  def named
    @named = true
  end

  # It won't generate node class, but instead it will use one passed as an argument. The argument is actual
  # class object, not a symbol
  def node_class(cls)
    @node_class = cls
  end

  # Unprocessed node with this symbol will be converted into the generated node class
  def symbol(expected_symbol)
    @expected_symbol = expected_symbol
  end

  # Generates node class and fix_xyz method
  def gen
    expected_symbol = gen_expected_symbol
    fix_method_name = gen_fix_method_name

    # Skip node class generation if defined explicitly
    unless @node_class
      aliases = @aliases
      class_target = @class_target
      expected_len = @expected_len
      named = @named
      node_class_name = gen_node_class_name
      if const_defined? node_class_name
        # Add to existing node class
        cls = const_get node_class_name
      else
        # Completely new node class
        cls = Object.const_set node_class_name, Class.new(Node)
      end

      cls.class_eval do

        # Constructor
        define_method :initialize do
          |ruby_node, children|
          super()
          @ruby_node = ruby_node
          expect_len(expected_len, children) if expected_len
          if respond_to? :transform_children
            children = transform_children children
          end
          assign_children children
        end

        # For named methods add name to to_s()
        if named
          define_method :to_s do
            "#{node_class_name}(#{name})"
          end
        else
          define_method :to_s do
            node_class_name
          end
        end

        # Getters and setters for aliases
        aliases.each do
          |a|
          self.send :define_method, a.new_name do
            self.send a.old_name
          end
          self.send :define_method, (a.new_name.to_s + '=') do
            |value|
            self.send a.old_name.to_s + '=', value
          end
        end

        if class_target
          define_method :cls do
            self
          end
        end

        if named
          define_method :name do
            child.load_name
          end
          define_method :load_name do
            child.load_name
          end
        end
      end
    end

    node_class = gen_node_class

    # Generate the UnprocessedNode#fix_xyz()
    UnprocessedNode.send :define_method, fix_method_name do
      return self unless symbol? expected_symbol.to_s
      return node_class.new @ruby_node, children
    end
  end

  protected

  def plain_name
    unless name.end_with? 'Fix'
      fail "Fix name should end with Fix, but got #{name}"
    end
    name[0..-4].downcase # strip Fix from name
  end

  def gen_expected_symbol
    @expected_symbol ? @expected_symbol.to_s : plain_name
  end

  def gen_fix_method_name
    "fix_#{gen_expected_symbol}"
  end

  def gen_node_class
    @node_class ? @node_class : eval(gen_node_class_name)
  end

  def gen_node_class_name
    class_name = @class_name.nil? ? plain_name.capitalize : @class_name
    "#{class_name}Node"
  end
end

$dsl_fixes = []

def gen_dsl_fixes
  for fix in $dsl_fixes
    fix.gen
  end
end
