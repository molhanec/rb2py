class CbaseNode

  def pyfix_encoding
    if parent.is_a? ConstantNode and parent.name == 'Encoding'
      return NewValueNode.new nil, 'rb2py'
    end
    return self
  end
end
