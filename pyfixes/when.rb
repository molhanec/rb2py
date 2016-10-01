class WhenNode

  alias :statements :last_child

  def value(bt: caller)
    stop! "WhenNode::value() removed", bt: caller
  end

  def values
    children[0...-1] # all but last
  end
end
