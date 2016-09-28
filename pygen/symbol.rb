# Simple :symbol

class SymbolNode
  def real_gen
    $pygen.symbol value
  end
end

class SymbolLeafNode
  def real_gen
    $pygen.write value
  end
end