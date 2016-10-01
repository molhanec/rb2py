require_relative 'class_resolve_ancestor'

# shared by InstanceTestNode
module InstantiationFullname

  require_relative 'fullname'
  attr_reader :fullname

  def fix_resolve_ancestor
    @fullname = real_resolve_ancestor class_name
    return self
  end
end


class InstantiationNode < Node

  include InstantiationFullname
end
