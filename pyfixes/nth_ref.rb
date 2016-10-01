class RegexNthCaptureNode

  def pyfix_nth_ref
    def_node = find_surrounding DefNode
    def_node.regexp_captures = true
    return self
  end
end
