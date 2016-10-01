module PyfixSuper
  def pyfix_super
    def_node = find_surrounding DefNode
    if def_node.name == 'initialize'
      class_node = find_surrounding ClassNode
      class_node.calls_super_initialize = true
    end
    return self
  end
end


class SuperNode
  include PyfixSuper
end


class SuperWithoutArgsNode
  include PyfixSuper
end
