#   class A
#     include B
#     class B
# ==>
#   class B
#   class A
#     include B

$extracted_classes = []

class ClassNode

  def pyfix_class_extract
    result = [self]
    change = true
    while change
      change = false
      filter_children(IncludeNode) {
        |include_node|
        if enclosed_classes.include? include_node.fullname
          included_class = nil
          all_classes {
            |cls|
            if cls.fullname == include_node.fullname
              included_class = cls
              break
            end
          }
          result.unshift included_class
          change = true
          enclosed_classes.delete include_node.fullname
          included_class.parent.children.delete included_class
          $extracted_classes << included_class
        end
      }
    end
    return result
  end
end


class ClassOrModuleNode
  def pyfix_class_flatten
    result = [self]

    change = true
    while change
      change = false
      filter_children(ClassNode) {
        |cls|
        if $HINTS_FLATTEN_CLASSES.include? cls.fullname.to_s
          d "Flattening #{cls.fullname.to_s}"
          result.unshift cls
          change = true
          enclosed_classes.delete cls.fullname
          cls.parent.children.delete cls
          cls.save_original_fullname
          cls.fullname = parent.fullname + cls.fullname.last_part
          $extracted_classes << cls
        end
      }
    end
    return result
  end
end
