# Regular expression

class RegexpNode

  def pyfix_regexp
    $pygen.imports << 're'
    if pattern.size > 1
      merged_pattern = ArrayNode.new ruby_node, pattern
    else
      merged_pattern = pattern[0]
    end
    make_rb2py_call 'create_regexp', merged_pattern, options
  end
end
