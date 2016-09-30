#   x.method(y) {|i| b}
# ==>
#   for i in x(y):
#     b

class CustomBlockNode
  def real_gen
    $pygen.write "for #{joined_arguments} in "
    send_node.gen
    $pygen.write ':'
    $pygen.indented{
      statements.gen
    }
  end
end
