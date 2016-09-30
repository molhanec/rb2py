#   x.times {|a| s}
# ==>
#   for a in range(x): s
class TimesNode
  def real_gen

    $pygen.write "for #{joined_arguments} in range("
    target.gen
    $pygen.write '):'
    $pygen.indent_inc
      gen_children
    $pygen.indent_dec
  end
end
