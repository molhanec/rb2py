
# Represents whatever class is used as a user's own
# exception classes base
class UserExceptionAncestor; end


STANDARD_CLASSES = {
    'Array' => ArrayNode,
    'String' => StringNode,
    'StandardError' => UserExceptionAncestor,
}


EMULATED_CLASSES = [
    'Marshal',
    'Zlib::Deflate',
    'Zlib::Inflate',
]

class EmulatedClassNode < Node

  attr_reader :name

  def initialize(ruby_node, name)
    super(ruby_node)
    @name = name
  end

  def to_s
    "Emulated(#{name})"
  end

  alias fullname name
end

class Node
  def get_standard_class(classname)
    classname = classname.to_s
    if EMULATED_CLASSES.include? classname
      return EmulatedClassNode.new ruby_node, classname
    end
    return STANDARD_CLASSES[classname]
  end
end
