require 'set'

class AssignLocalVarNode

  def pyfix_assign_local_var
    def_node = find_surrounding DefNode
  rescue
    # TODO
  else
    def_node.local_vars << name
  ensure
    return self
  end
end


class DefNode
  def local_vars
    @local_vars ||= SortedSet.new
  end
end
