#   x.upto(y) {|i| b}
# ==>
#   for i in range(x, y + 1):
#     b

class UptoNode
  def real_gen
    $pygen.write "for #{joined_arguments} in range("
    from.gen
    $pygen.write ', '
    to.gen
    $pygen.write ' + 1):'
    $pygen.indent_inc
      gen_children
    $pygen.indent_dec
  end
end
