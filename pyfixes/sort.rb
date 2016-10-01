#   x.sort {|a, b| return a <=> b}
# ==>
#   def _block_XXXX(a, b):
#     return rb2py.cmp1(a, b)
#   list(sorted(x, key=functools.cmp_to_key(_block_XXXX)))


class SortNode
  attr_accessor :block_name
  def pyfix_sort
    #   def _block_XXXX(a, b):
    block_name = "_block_#$last_block_id"
    $last_block_id += 1
    # initialize(ruby_node, name, arguments, body)
    block_def = BlockEmulationDefNode.new ruby_node, block_name, arguments, statements
    block_def.true_method = false

    # list(sorted(x, key=functools.cmp_to_key(_block_XXXX)))
    $pygen.imports << 'functools'
    cmp_to_key_call = make_custom_target_call 'functools', 'cmp_to_key', block_name
    sorted_call = make_global_call 'sorted', target, (PythonKeyedArgument.new 'key', cmp_to_key_call)
    list_call =  make_global_call 'list', sorted_call


    # find current statement list
    statement_list, statement_list_child = current_statement_list

    # if we place the block definition just before ourselves
    statement_list_child = list_call if statement_list_child == self

    statement_list.late_insert before: statement_list_child, node: block_def

    return list_call
  end
end


class PythonKeyedArgument < Node

  attr_reader :name

  def initialize(name, value)
    super()
    @name = name
    assign_children [value]
  end

  def real_gen
    $pygen.write "#{name}="
    gen_children
  end
end
