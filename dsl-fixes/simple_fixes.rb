# The simple input transformations are implemented here using internal DSL. For each individual transformation there
# should be exactly one class which is descendant of Fix class defined in fix.rb.
# The name should correspond to the matching symbol of the input AST with "Fix" suffix,
# e.g. "AndFix" for the "and" symbol.
#
# Note that just defining the fix is not enough! You must as well call the fix on a node in the toplevel.rb.
# The name for a fix for a "XyzFix" class will be "fix_xyz"
#
# DSL usage:
#
# class XyzFix
#   # This will generate and add "fix_xyz" method to the UnprocessedNode class.
#   # Unless "node_class" is specified it will also generate node class "XyzNode".
#
#   alias_child :name_for_a_property, :second_child
#   # In the instances of "XyzNode" the the "second_child" will be also available as "name_for_a_property" getter.
#   # E.g. "xyz_node.second_child" <===> "xyz_node.name_for_a_property"
#   # Also the the "second_child=" will be also available as "name_for_a_property=" setter.
#   # E.g. "xyz_node.second_child=" <===> "xyz_node.name_for_a_property="
#
#   class_name :Abc
#   # Generated node class will be named "AbcNode" instead of "XyzNode"
#   # Note that "Node" is added automatically and is not part of the name
#
#   class_target
#   # This will generate "def cls; self; end" getter for static analysis
#
#   expect_len NUMBER
#   # Will check number of children
#
#   named
#   # It will generate "name" and "load_name" methods for node_class which will delegate the call to the first child
#   # "load_name" method
#
#   node_class XxxYyyZzzNode
#   # It won't generate node class, but instead it will use one passed as an argument. The argument is actual
#   # class object, not a symbol
#
#   symbol 'abc'
#   # This fix will convert unprocessed nodes with "abc" symbol, not "xyz" (which would be extracted from "XyzFix"
#   # class name)
#
#   def transform_children(children)
#     return do_something(children)
#   end
#   # Allows you to manipulate children before they are assigned to node class instance
#   # expect_len is tested before transform_children() call
# end

# Internal DSL implementation
require_relative 'fix'

# Import directly used classes
require_relative '../fixes/alias'
require_relative '../fixes/assign'
require_relative '../fixes/block'
require_relative '../fixes/node_with_class'
require_relative '../fixes/op-asgn'
require_relative '../fixes/range'
require_relative '../fixes/class_resolve_ancestor'


# class Xyz
#   alias new_method_name old_method_name
# end
class AliasFix < Fix
  node_class AliasNode
end


# Logical and
class AndFix < Fix
  alias_child :left, :first_child
  alias_child :right, :second_child
  class_target
  expect_len 2
end


# Normal position-based argument without default value
class ArgFix < Fix
  class_name :SimpleArgument
  class_target
  expect_len 1
  named
end
class SimpleArgumentNode < Node
  include NodeWithClass
end


# ArgumentList. All method arguments are not direct children of DefNode, but instead inside ArgumentListNode.
class ArgsFix < Fix
  class_name :ArgumentList
end
class ArgumentListNode < Node

  def argument_names
    children.map {|a| a.name}
  end

  # If there is explicit block argument
  #   def method(normal_1, normal_2, &block)
  # finds it and returns it. Otherwise returns nil.
  def block_argument
    block_arguments = filter_children(BlockArgumentNode)
    if block_arguments.size == 0
      return nil
    elsif block_arguments.size == 1
      return block_arguments[0]
    else
      stop! "Only one block argument allowed"
    end
  end
end


# Array literal
class ArrayFix < Fix
  class_target
end
class ArrayNode < Node
  def self.fullname
    'list'
  end
end


# Parens ()
class BeginFix < Fix; end
class BeginNode < Node
  def cls; nil end
end


# Expplicit block argument
#   def method(&block)
class BlockargFix < Fix
  class_name :BlockArgument
  class_target
  expect_len 1
  named
end
class BlockArgumentNode < Node
  include NodeWithClass
end


# Block. Method call with block
#   method { block }
# is on the AST level represented as a BlockNode with SendNode inside
class BlockFix < Fix
  expect_len 3
  node_class BlockNode  # in fixes/block.rb
end


# Passing block obtained e.g. as block argument to another method
#   calling_method 1, 2, &passed_block
class BlockPassFix < Fix
  symbol 'block_pass'
end


# break keyword
class BreakFix < Fix
end


# case control expression
class CaseFix < Fix
  class_target
end


# :: namespace specifier, meaning that the specified path is absolute
class CbaseFix < Fix; end
class CbaseNode < Node
  def load_name
    # TODO proper implement
    w1 'CBase load_name'
    return "rb2py"
    # nil
  end
end


# Constant.
# In Ruby, constants are also Class and Module identifiers etc.
class ConstFix < Fix
  class_target
  class_name :Constant
end
class ConstantNode < Node

  # We don't use
  #   named
  # in the ConstFix because that would delegate name to first child and that is not what we want.
  def name
    @name or load_name
  end
  attr_writer :name

  def fix_resolve_ancestor
    @name = real_resolve_ancestor name
    return self
  end
end


# Class variable @@variable_name
class CvarFix < Fix
  class_name :ClassVariable
end
class ClassVariableNode < Node
  include NodeWithClass
  def name
    child.load_name[2..-1] # strip @@
  end
  alias load_name name
end


# Assignment to class variable
#   @@variable_name = 123
class AssignClassVarNode < AssignGenericNode

  alias :value :second_child
  alias :value= :second_child=

  def initialize(ruby_node, children)
    super ruby_node
    assign_children (transform_children children)
  end

  def transform_children(children)
    value = case children.size
              when 1 then MissingNode.new self, ruby_node  # Part of multiple assignment
              when 2 then children[1]
              else stop! 'Expected 1 or 2 children'
            end
    return [children[0], value]
  end

  def name
    first_child.load_name[2..-1] # strip @@
  end

  def to_s
    "AssignClassVarNode(#{name})"
  end

  def fix_attribute
    class_node = find_surrounding ClassNode
    attribute = class_node.find_static_attribute name
    unless attribute
      attribute = class_node.add_static_attribute ruby_node, name
      d "#{attribute} #{class_node} #{value} static"
    end
    attribute.cls = value.cls if value.respond_to? 'cls'
    @attribute = attribute
    return self
  end
end
class CvasgnFix < Fix
  node_class AssignClassVarNode
end


# ensure keyword
#   begin
#     protected statements (this will became first child)
#   ensure
#     ensured statements (this will became second child)
#   end
# In many other programming languages this is called "finally".
class EnsureFix < Fix
  expect_len 2
  alias_child :protected, :first_child
  alias_child :ensured, :second_child
end
class EnsureNode < Node
  def transform_children(children)
    [
        children[0].make_statement_list,
        children[1].make_statement_list,
    ]
  end
end


# Exclusive, i.e. three-dot, range
#   3...5
class ErangeFix < Fix
  expect_len 2
  node_class RangeExclusiveNode  # in fixes/range
end


# false literal
class FalseFix < Fix
  class_target
  expect_len 0
end


# Real number literal
class FloatFix < Fix
  class_target
  expect_len 1
end


# Global variable
class GvarFix < Fix
  class_name :GlobalVariable
  named
end


# Hash literal
class HashFix < Fix
  class_target
end
class HashNode < Node
  def transform_children(children)
    unless children.all? { |c| c.symbol? 'pair' }
      stop! 'Hash should have only pairs as children'
    end
    children
  end
end


# if/unless literal
class IfFix < Fix
  expect_len 3
  alias_child :condition, :first_child
  alias_child :when_true, :second_child
  alias_child :when_false, :third_child
end
class IfNode < Node
  def transform_children(children)
    [
        children[0],
        children[1].make_statement_list,
        children[2].make_statement_list
    ]
  end
  def cls; self end
end


# Integer number literal
class IntFix < Fix
  class_target
  expect_len 1
end


# Inclusive, i.e. two-dot, range
#   3..5
class IrangeFix < Fix
  expect_len 2
  node_class RangeInclusiveNode  # in fixes/range
end


# Instance variable
class IvarFix < Fix
  class_name :InstanceVariable
  expect_len 1
end
class InstanceVariableNode < Node
  include NodeWithClass
  def name
    child.load_name[1..-1] # strip @
  end
  alias load_name name
end


# Instance variable assignment
class AssignInstanceVarNode < AssignGenericNode

  alias :target :second_child
  alias :value :third_child
  alias :value= :third_child=

  def initialize(ruby_node, children)
    super ruby_node
    assign_children (transform_children children)
  end

  def transform_children(children)
    value = case children.size
              when 1 then MissingNode.new self, ruby_node # inside multiple assignment
              when 2 then children[1]
              else stop! 'Expected 1 or 2 children'
            end
    target = SelfNode.new(ruby_node)
    return [children[0], target, value]
  end

  def name
    first_child.load_name[1..-1] # strip @
  end

  def to_s
    "AssignInstanceVarNode(#{name})"
  end

  # Copied from AssignInstanceNode
  # TODO Refactor to use same code!
  def fix_attribute
    # return self unless value.respond_to? :cls
    class_node = find_surrounding ClassOrModuleNode
    def_node = find_surrounding DefNode
    if def_node.static_method?
      attribute = class_node.find_static_attribute name
      unless attribute
        attribute = class_node.add_static_attribute ruby_node, name
        d "#{attribute} #{class_node} #{value} static"
      end
    else
      attribute = class_node.find_attribute name
      unless attribute
        attribute = class_node.add_attribute ruby_node, name
        d "#{attribute} #{class_node} #{value}"
      end
    end
    attribute.cls = value.cls if value.respond_to? 'cls'
    @attribute = attribute
    return self
  end

  # Creates getter for this variable
  def getter
    InstanceVariableNode.new ruby_node, [first_child.deep_copy]
  end
end
class IvasgnFix < Fix
  node_class AssignInstanceVarNode
end


# Keyword 'begin' alone
class KwbeginFix < Fix
  class_name :BeginKeyword
end


# Local variable assignment
class LvasgnFix < Fix
  expect_len 2
  node_class AssignLocalVarNode  # in fixes/assign
end


# Local variable
class LvarFix < Fix
  class_name :LocalVariable
  expect_len 1
  named
end
class LocalVariableNode < Node

  include NodeWithClass

  # Tries to statically analyse class of local variable
  def fix_class_reference
    d "Searching for local var #{name}"
    parent = self.parent
    # until we run of the current def
    # (note that the statements are inside StatementListNode so we can test this on the beginning of the loop)
    until parent.is_a? DefNode
      if parent.nil?
        return self
      end
      for child in parent.children
        # Normal local variable
        #    x = 5
        if child.is_a? AssignLocalVarNode and child.name == name
          d "  Found local var #{name}"
          @cls = child.value.cls
          d "  guessed class: #{cls.inspect}"
          return self
        end
        # Local variable in the for-each loop
        #    for x in [1, 2, 3]
        if child.is_a? EachNode and child.argument_names.include?(name)
          d "  Found each loop var #{name}"
          @cls = child.target.guess_each_class
          d "  guessed class: #{cls.inspect}"
          return self
        end
      end
      parent = parent.parent
    end
    parent.expect_class DefNode
    for argument in parent.arguments.children
      # Local variable from the method argument list
      if argument.name == name
        d "  Found argument var #{name}"
        @cls = argument.cls
        d "  guessed class: #{cls.inspect}"
        return self
      end
    end
    return self
  end
end


# Multiple assignment
#   a, b, c = 1, 2, 3
class MasgnFix < Fix
  expect_len 2
  node_class MultipleAssignmentNode  # in fixes/assign
end


# Multiple assignment left hand side
class MlhsFix < Fix
  class_name :MultipleAssignmentLeftHandSide
end
class MultipleAssignmentLeftHandSideNode < Node
  def argument_names
    children.map do |argument|
      argument.name
    end
  end
end


# next keyword
class NextFix < Fix
  expect_len 0
end


# nil literal
class NilFix < Fix
  class_target
  expect_len 0
end


# Reference to n-th captured group of last regexp match, e.g. $3
class NthRefFix < Fix
  class_name :RegexNthCapture
  symbol 'nth_ref'
end


# Argument with default value
class OptargFix < Fix
  alias_child :default_value, :second_child
  class_name :OptionalArgument
  class_target
  expect_len 2
  named
end
class OptionalArgumentNode < Node
  include NodeWithClass
end


# Operator assignment
#   +=, -= etc.
class OpAssignFix < Fix
  alias_child :target, :first_child
  alias_child :operator, :second_child
  alias_child :value, :third_child
  node_class OperatorAssignNode
  expect_len 3
  symbol 'op_asgn'
end


# Logical or
class OrFix < Fix
  alias_child :left, :first_child
  alias_child :right, :second_child
end
class OrNode < SubexpressionNode
  def cls; self; end
end


# Pair is key-value tuple of hash
class PairFix < Fix
  alias_child :key, :first_child
  alias_child :value, :second_child
  expect_len 2
end


# Regular expression literal
class RegexpFix < Fix
  alias_child :options, :last_child
  class_target
end
class RegexpNode < Node
  def pattern
    children[0...-1] # last one is options
  end
end


# Options for regular expression
class RegoptFix < Fix; end


# Body of the rescue statement
class ResbodyFix < Fix
  class_name :RescueBody
  alias_child :exception_class, :first_child
  alias_child :exception_variable, :second_child
  alias_child :statements, :third_child
  expect_len 3
end
class RescueBodyNode < Node
  def transform_children(children)
    [
        children[0],
        children[1],
        children[2].make_statement_list,
    ]
  end
end


# rescue statement
class RescueFix < Fix
  expect_len 3
  alias_child :protected, :first_child
  alias_child :rescued, :second_child
end
class RescueNode < Node
  def transform_children(children)
    children[2].expect_class MissingNode
    return [
        children[0].make_statement_list,
        children[1],
    ]
  end
end


# Catch the rest arguments
#   *args
class RestargFix < Fix
  class_name :RestArgument
  class_target
  expect_len 1
  named
end
class RestArgumentNode < Node
  include NodeWithClass
end


# return keyword
class ReturnFix < Fix
  alias_child :value
end


# Eigen-class
#   class << self ... end
class SclassFix < Fix
  alias_child :target
  class_name :EigenClass
end
class EigenClassNode < Node
  def elements
    # first one is the target
    children[1..-1]
  end
end


# *args
class SplatFix < Fix; end


# String
class StringFix < Fix
  alias_child :value
  class_target
  expect_len 1
  symbol :str
end
class StringNode < Node
  def self.fullname
    'str'
  end
end


# Dstr means double-quoted string.
# Parser already transforms it into parts.
class StringInterpolatedFix < Fix
  class_name :StringInterpolated
  class_target
  symbol :dstr
end
class StringInterpolatedNode < Node
  def transform_children(children)
    children.map &:make_expression
  end
end


# super() call with explicit arguments
class SuperFix < Fix
  class_target
end


# Symbol
class SymbolFix < Fix
  expect_len 1
  class_target
  symbol :sym
end
class SymbolNode < Node
  def value
    child.load_name
  end
  def expect_symbol
    true
  end
end


# Dsym means double-quoted symbol, i.e. :"symbol"
# Parser already transforms it into parts.
class SymbolInterpolatedFix < Fix
  class_name :SymbolInterpolated
  class_target
  symbol :dsym
end
class SymbolInterpolatedNode < Node
  def transform_children(children)
    children.map &:make_expression
  end
  def expect_symbol
    true
  end
end


# true literal
class TrueFix < Fix
  class_target
  expect_len 0
end


# yield literal
class YieldFix < Fix
  class_target
end


# until control expression
class UntilFix < Fix
  expect_len 2
  alias_child :condition, :first_child
  alias_child :statements, :second_child
end
class UntilNode < Node
  def transform_children(children)
    [
        children[0],
        children[1].make_statement_list,
    ]
  end
  def cls; self end
end


# Single "when" part inside "case" control expression
class WhenFix < Fix; end
class WhenNode < Node
  def transform_children(children)
    [
        *children[0...-1],
        children[-1].make_statement_list,
    ]
  end
end


# while control expression
class WhileFix < Fix
  alias_child :condition, :first_child
  alias_child :statements, :second_child
  expect_len 2
end
class WhileNode < Node
  def transform_children(children)
    [
        children[0],
        children[1].make_statement_list,
    ]
  end
  def cls; self end
end


# "super" call without arguments. This will automatically pass all arguments of current method to the method
# called by super.
class ZSuperFix < Fix
  class_name :SuperWithoutArgs
  expect_len 0
end
