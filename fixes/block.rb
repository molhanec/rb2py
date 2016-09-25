# Translate blocks

require_relative 'any'
require_relative 'delete_if'
require_relative 'detect'
require_relative 'each'
require_relative 'each_with_object'
require_relative 'find'
require_relative 'gsub'
require_relative 'hash_block'
require_relative 'inject'
require_relative 'loop'
require_relative 'map'
require_relative 'map_in_place'
require_relative 'open'
require_relative 'partition'
require_relative 'select'
require_relative 'sort'
require_relative 'times'
require_relative 'upto'


class BlockNode < Node

  attr_reader :message_name
  alias send_node first_child
  alias arguments second_child
  alias statements third_child

  def target
    send_node.target
  end

  def initialize(ruby_node, children)
    super(ruby_node)
    send_node = children[0]
    stop! 'First child of Block must be a SendNode or InstantiationNode' unless (send_node.is_a? SendNode or send_node.is_a? InstantiationNode)
    args_node = children[1]
    stop! 'Second child of Block must be a ArgumentListNode' unless args_node.is_a? ArgumentListNode
    if send_node.is_a? SendNode
      @message_name = send_node.message_name
    else
      @message_name = send_node.class_name
    end
    statements = children[2].make_statement_list
    assign_children [send_node, args_node, statements]
  end

  def to_s
    'Block'
  end

  # These block calls have special node class
  BLOCK_CALLS = {
    'any?' => AnyNode,
    'collect' => MapNode, # alias for map
    'delete_if' => DeleteIfNode,
    'detect' => DetectNode,
    'each' => EachNode,
    'each_with_index' => EachWithIndexNode,
    'each_with_object' => EachWithObjectNode,
    'find' => FindNode,
    'hash_block' => HashBlockNode,
    'gsub' => GSubNode,
    'Hash' => HashBlockNode,
    'inject' => InjectNode,
    'loop' => LoopNode,
    'map' => MapNode,
    'map!' => MapInPlaceNode,
    'open' => OpenNode,
    'partition' => PartitionNode,
    'reverse_each' => EachReverseNode,
    'select' => SelectNode,
    'sort' => SortNode,
    'times' => TimesNode,
    'upto' => UptoNode,
  }

  # These calls are specially translated only if they are called on a specific class target
  BLOCK_CALLS_CLASS_LIMITED = {
    'open' => 'File',
  }

  def fix_block_calls
    # Get special node class if any
    class_node = BLOCK_CALLS[message_name]

    # If we expect special class target check it
    classes = BLOCK_CALLS_CLASS_LIMITED[message_name]
    if classes and (not classes.include? target.cls.fullname.to_s)
      class_node = nil
    end

    # If there was special a special node class, make instance of it
    return class_node.new self if class_node

    # Otherwise return generic CustomBlock
    w1 "Unknown block message #{message_name}"
    return CustomBlockNode.new self
  end

  def cls
    nil
  end

  def argument_names
    # self.arguments is ArgumentListNode instance
    @argument_names ||= arguments.children.map {
      |argument|
      if argument.respond_to? :argument_names
        argument.argument_names
      else
        argument.name
      end
    }.flatten
    return @argument_names
  end
end
