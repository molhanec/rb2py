# If class B inherits from class A make sure, that A precedes B.

class ClassOrModuleNode
  def pyfix_class_reorder
    d "Before reorder: #{children}"
    change = true
    while change
      change = false
      for child, index in children.each_with_index
        next unless child.is_a? ClassNode
        last_dependency_index = 0
        for possible_dependency, possible_dependency_index in children.each_with_index
          next unless possible_dependency.is_a? ClassNode
          for dependency in child.dependencies
            if possible_dependency.enclosed_classes.include? dependency
              if possible_dependency_index > last_dependency_index
                last_dependency_index = possible_dependency_index
              end
              next
            end
          end
        end
        if last_dependency_index > index
          d "Moving class #{children[index].fullname} behind #{children[last_dependency_index].fullname}"
          children.insert last_dependency_index + 1, child
          children.delete_at index
          change = true
          break
        end
      end
    end
    d "After reorder: #{children}"
    return self
  end
end
