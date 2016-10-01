class GlobalVariableNode

  def pyfix_global_variable
    if name == '$DEBUG'
      w1 "$DEBUG global variable translated to True"
      return TrueNode.new ruby_node, []
    end
    stop! "Global variable '#{name}' not supported"
  end
end
