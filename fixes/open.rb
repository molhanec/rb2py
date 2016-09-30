class OpenNode < BlockFixNode

  def initialize(block)
    d block.target
    block.target.expect_class ClassTargetNode
    stop! "Unknown open for #{block.target}" unless block.target.cls.fullname.to_s == 'File'
    super
    if send_node.arguments.count != 2
      stop! "Unexpected count of File.open() arguments:\n  " + send_node.arguments.join("\n  ") + "\n"
    end
  end

  def filename
    send_node.arguments[0]
  end

  def mode
    send_node.arguments[1]
  end

  def to_s
    "Open(#{filename})"
  end

  def cls
    self
  end
end
