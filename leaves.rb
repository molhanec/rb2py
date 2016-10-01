# Leaf AST nodes

class LeafNode < NoChildrenNode

  def initialize(parent=nil, ruby_node=nil)
    super()
    @parent = parent
    @ruby_node = ruby_node
  end

  def name
    fail "Plain leaf node not allowed"
  end

  def to_s
    name + 'Leaf'
  end

  def ruby_node_to_s
    @ruby_node.to_s
  end

  def expect_len(len)
    if len != 0
      fail "Expected length #{len}, but this is leaf node #{self}"
    end
  end

  def fix _
    self
  end
end


# Note that this node means nil as "missing in AST"
# and not nil in the source file. That is represented
# as a symbol.
class MissingNode < LeafNode

  def name
    'Missing'
  end

  def missing?
    true
  end

  def expect_missing
    true
  end

  def load_name
    nil
  end

  def cls
    self
  end
end


class ValueLeafNode < LeafNode

  def to_s
    "#{super.to_s}(#{ruby_escaped_value})"
  end

  def value
    @ruby_node.to_s
  end
  alias ruby_escaped_value value
end


class SymbolLeafNode < ValueLeafNode

  def name
    'Symbol'
  end

  def expect_symbol
    true
  end

  def expect(what)
    if ruby_node_to_s != what
      fail "Expected #{what}, but found #@ruby_node"
    end
  end

  alias load_name ruby_node_to_s

  def symbol?(*names)
    names.include? ruby_node_to_s
  end
end


class StringLeafNode < ValueLeafNode

  def name
    'String'
  end

  def ruby_escaped_value
    # quick hack to escape string
    # see http://stackoverflow.com/questions/8639642/best-way-to-escape-and-unescape-strings-in-ruby
    value.inspect[1..-2]
  end
end


class NumberLeafNode < ValueLeafNode
  def name
    'Number'
  end
end

# for value nodes not in the original source
class NewValueNode < NoChildrenNode

  attr_reader :value
  alias name value

  def initialize(ruby_node, value)
    super()
    @ruby_node = ruby_node
    @value = value
  end

  def load_name
    value.to_s
  end

  def to_s
    "NewValue(#{value})"
  end

  def ruby_node_to_s
    value
  end

  def expect_len(len)
    if len != 0
      fail "Expected length #{len}, but this is leaf node #{self}"
    end
  end

  def fix _
    self
  end

  def cls
    self
  end
end
