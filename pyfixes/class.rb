# Fix situation when a class inherits from class which it contains.
# E.g.
#   class A
#     class B < A
#     end
#   end
# ==>
#   class A:
#     ...
#   class B:
#     ...
#   A.B = B

class ClassNode

  def pyfix_class
    result = [self]
    new_children = []
    for child in children
      # if child is a class that inherits from me
      if child.is_a? ClassNode and child.ancestor == fullname
        original_name = child.name
        result << child
        result << (NewValueNode.new ruby_node, "#{name}.#{original_name} = #{child.name}")
        next # skip adding to children
      end
      new_children << child
    end
    assign_children new_children
    return result
  end
end
