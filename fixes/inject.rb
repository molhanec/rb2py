class InjectNode < BlockFixNode

  def initial
    send_node.arguments[0]
  end

  def to_s
    "Inject(#{argument_names})"
  end

  def cls
    self
  end
end
