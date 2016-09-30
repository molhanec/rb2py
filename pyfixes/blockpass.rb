# Because it is keyword argument, it must go after all positional arguments

class SendNode

  def pyfix_blockpass
    for child in children
      if child.is_a? BlockpassNode
        # put it at the end
        children.delete child
        children << child
        break
      end
    end
    return self
  end
end