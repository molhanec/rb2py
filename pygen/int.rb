# Integer

class IntNode
  def real_gen
    child.gen
  end
end

class NumberLeafNode
  def gen
    $pygen.write ruby_node_to_s
  end
end
