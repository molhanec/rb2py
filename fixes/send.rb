# Send a message a.k.a. call a method

class Node
  def make_target(target)
    if target.is_a? ConstantNode
      return make_class_target target.load_name
    end
    if target.missing?
      # implicit self target
      return SelfNode.new(target.ruby_node)
    end
    return target
  end

  def make_global_target(parent=self, ruby_node=@ruby_node)
    MissingNode.new(parent, ruby_node)
  end
end


class UnprocessedNode

  def fix_send
    return self unless symbol? 'send'

    if first_child.is_a? ConstantNode and first_child.name == 'Math'
      return make_math_call
    end

    # It's not call per se, but object instantiation
    if second_child.symbol? 'new'
      if first_child.is_a? MissingNode
        # Instantiation in class method, e.g.
        # class C
        #   def self.m # class method
        #     return new # Create C instance
        #   end
        # end
        return make_self_instantiation
      else
        return make_instantiation
      end
    end

    if second_child.symbol? '!'
      return make_operator_not
    end

    if second_child.symbol? '==='
      return make_operator_case_comparison
    end

    if second_child.symbol? '>', '>=', '<', '<=', '==', '!='
      return make_operator_comparison
    end

    if second_child.symbol? '=~'
      return make_match_operator
    end

    if second_child.symbol? '<<'
      return make_operator_append
    end

    if second_child.symbol? '[]'
      return make_operator_index
    end

    if second_child.symbol? '[]='
      return make_operator_index_assign
    end

    if second_child.symbol? '+', '-', '*', '/', '**', '&', '|', '^', '>>'
      return make_operator_binary
    end

    if second_child.symbol? '+@', '-@', '~'
      return make_operator_unary
    end

    if second_child.symbol? '%'
      return make_operator_format
    end

    if second_child.symbol? 'alias_method'
      first_child.expect_missing # target should be nil
      expect_len 4 # nil, :alias_method, new_name, old_name
      return AliasNode.new ruby_node, [third_child, fourth_child]
    end

    if second_child.symbol? 'delegate'
      return make_delegates
    end

    expect_min_len 2
    target = first_child
    message_name = second_child.load_name
    arguments = children[2..-1]

    # Handle test for nil
    if message_name == 'nil?'
      stop! 'nil? should not have parameters' unless arguments.size == 0
      return NilTestNode.new ruby_node, target
    end

    # Mixins
    if message_name == 'include'
      expect_len 3
      parent.expect_class ClassNode
      target.expect_class MissingNode
      return IncludeNode.new ruby_node, third_child.load_name
    end

    # Handle exception raising
    if message_name == 'raise' or message_name == 'fail'
      stop! "raise should have no target #{self}" unless target.missing?
      return RaiseNode.new ruby_node, arguments
    end

    # Imports
    if message_name == 'require'
      return make_require
    end

    if message_name == 'require_relative'
      return self
    end

    # Access type
    if ['private', 'protected', 'module_function'].include? message_name
      # FIXME module_function does not belong here
      return PrivateNode.new ruby_node, message_name
    end

    # Handle attributes definition.
    if target.is_a? MissingNode and
        ['attr_accessor', 'attr_reader', 'attr_writer'].include? message_name
      return make_attribute
    end

    target = make_target(target)

    # Handle attributes assignment
    if message_name.end_with? '='
      attribute_name = message_name[0...-1] # exclude =
      unless parent.is_a? MultipleAssignmentLeftHandSideNode
        expect_one_argument message_name, arguments
        return AssignInstanceAttrNode.new ruby_node, target, attribute_name, arguments[0]
      else
        expect_no_argument message_name, arguments
        return AssignInstanceAttrNode.new ruby_node, target, attribute_name, MissingNode.new
      end
    end

    # Handle class instance test
    if ['kind_of?', 'is_a?'].include? message_name
      expect_one_argument message_name, arguments
      return InstanceTestNode.new ruby_node, [target, *arguments]
    end

    # Handle block testing
    if message_name == 'block_given?'
      target.expect_class SelfNode
      expect_len 2 # just target and message name
      return BlockGivenTestNode.new ruby_node
    end

    return SendNode.new ruby_node:ruby_node, target:target, message_name:message_name, arguments:arguments
  end

  def expect_no_argument(message_name, arguments)
    if arguments.size != 0
      stop! "Expected no arguments for #{message_name}", bt:caller
    end
  end

  def expect_one_argument(message_name, arguments)
    if arguments.size != 1
      stop! "Expected exactly one value for #{message_name}", bt:caller
    end
  end
end


class SendNode < SubexpressionNode

  # Send also has a type of a result associated
  include NodeWithClass

  alias target first_child
  alias target= first_child=

  attr_reader :message_name

  def arguments
    children[1..-1]
  end

  def first_argument
    arguments[0]
  end

  def first_argument=(argument)
    argument.parent = self
    children[1] = argument
  end

  def initialize(ruby_node:nil, target:nil, message_name:nil, arguments:nil)
    if target.nil? or message_name.nil? or arguments.nil?
      stop! "SendNode#initialize missing argument!"
    end
    super()
    @ruby_node = ruby_node
    @message_name = message_name
    assign_children [target, *arguments]
  end

  def to_s
    "Send(#{message_name})"
  end

  def expect_no_arguments
    # only target which is first child
    expect_len 1
  end

  def argument_count
    children.size - 1 # without target
  end

  def expect_arguments_count(n)
    expect_len n + 1 # n + target
  end


  # Some simple static analysis for guessing the result type

  def cls
    unless @cls or (not target.cls?)

      # it is a method?
      if target.cls.respond_to? :defs
        method = target.cls.defs.find do
          |method|
          method.name == message_name
        end
        if method
          return nil
          # @cls = method.cls #TODO
        end
      end

      # it is an instance attribute?
      if @cls.nil? and target.cls.respond_to? :attributes
        attr = target.cls.attributes.find do
          |attr|
          attr.name == message_name
        end
        if attr
          @cls = attr.cls
        end
      end
    end

    super
  end

  def guess_each_class
    cls? ? cls.guess_each_class : nil
  end

  def target_class?(cls)
    target.respond_to?(:cls) and not(target.cls.nil?) and (target.cls.is_a?(cls) or target.cls == cls)
  end
end
