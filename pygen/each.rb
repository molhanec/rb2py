#   x.each {|a| s}
#   x.each {|a, b| s}
# ==>
#   for a in x: s
#   for a, b in rb2py.each(x): s
class EachNode
  def real_gen
    $pygen.for_header{
      if arguments.children.size > 0
        arguments.gen{ $pygen.write ', ' }
      else
        $pygen.write 'rb2py_unused'
      end
    }

    $pygen.write 'reversed(' if reversed?

      # for more than one arguments process target through rb2py.each()
      # which handles dictionaries etc.
      if argument_names.size > 1
        $pygen.write 'rb2py.each'
        $pygen.paren do
          target.gen
        end
      else
        target.gen
      end

    $pygen.write ')' if reversed?

    $pygen.write ':'
    $pygen.indent_inc
      statements.gen
    $pygen.indent_dec
  end
end

class EachWithIndexNode
  def real_gen
    unless argument_names.size >= 2
      stop! "Expected at least two arguments"
    end

    # Reorder last argument (the index) as first.
    $pygen.write "for #{argument_names[-1]}, "
    rest = argument_names[0...-1]
    if rest.size > 1
      # wrap multiple arguments inside parens
      $pygen.paren do
        $pygen.write rest.join(", ")
      end
    else
      $pygen.write rest[0]
    end

    $pygen.write " in enumerate("; target.gen; $pygen.write '):'
    $pygen.indent_inc
      statements.gen
    $pygen.indent_dec
  end
end
