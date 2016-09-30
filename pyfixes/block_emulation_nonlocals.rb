#   def a
#     x = 1
#     ... do
#       x = 2
#     end
#   end
# ==>
#   def a():
#     x = 1
#     def _block_X():
#       nonlocal x       # adds this
#       x = 2

require 'set'

class BlockEmulationDefNode

  def pyfix_block_emulation_nonlocals
    searched = Set.new
    def_node = find_surrounding DefNode, ClassNode
    filter_recursive children, AssignLocalVarNode do
      |assignment|
      var_name = assignment.name
      unless searched.include? var_name
        searched << var_name
        if def_node.local_variable?(var_name, search_parent_defs:true)
          nonlocals << var_name
        end
      end
    end
    return self
  end
end


# We can share real_gen() method if it is defined for all defs
class DefNode
  def nonlocals
    @nonlocals ||= SortedSet.new
  end
end
