#   File.open(filename, mode) {|f| b}
# ==>
#   with open(str(filename), mode) as f:
#     b

class OpenNode
  def pyfix_open
    send_node.target = MissingNode.new nil, nil
    # wrap filename inside str()
    send_node.first_argument = make_global_call 'str', send_node.first_argument
    # send_node.assign_children [send_node.first_child, (make_global_call 'str', send_node.first_argument), *send_node.children[2..-1]]
    PythonWith.new [send_node, statements], arguments.child.name
  end
end


class PythonWith < Node

  alias send_node first_child
  alias statements second_child

  attr_reader :with_argument_name

  def initialize(children, with_argument_name)
    super(nil)
    assign_children children
    @with_argument_name = with_argument_name
  end

  def real_gen
    $pygen.write 'with '
    send_node.gen
    $pygen.write " as #{with_argument_name}:"
    $pygen.indent_inc
      gen_children
    $pygen.indent_dec
  end

  def to_s
    "PythonWith(#{with_argument_name})"
  end

  def get_result
    statements.get_result
    self
  end
end
