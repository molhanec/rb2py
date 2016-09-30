
# Common ancestor for Map, Detect, Inject etc.
class BlockFixNode < Node

  def prepare_new_block
    #   def _block_XXXX(arguments):
    #     code
    @block_name = "_block_#$last_block_id"
    $last_block_id += 1

    if arguments.children.size == 0
      # Create catch-all argument, because blocks can have arguments which are not taken. E.g. is fine to do
      #   def method
      #     yield 4
      #   end
      #   method { puts 'No arguments taken!' }
      # which must be converted to
      #   def _block_X(*args)
      arguments.add_child RestArgumentNode.new ruby_node, [(NewValueNode.new ruby_node, 'args')]
    end

    block_def = BlockEmulationDefNode.new ruby_node, @block_name, arguments, statements
    block_def.true_method = false
    return block_def, (BlockpassNode.new ruby_node, [(NewValueNode.new nil, @block_name)])
  end

  def insert_new_block(block_def, call)
    statement_list, statement_list_child = current_statement_list
    statement_list_child = call if statement_list_child == self
    statement_list.late_insert before: statement_list_child, node: block_def
  end
end
