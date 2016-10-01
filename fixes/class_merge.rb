# In Ruby one class can be defined on multiple places. Merge all the parts

module ClassMerge
  def fix_class_merge
    classes_seen = {}
    new_children = []
    for child in children
      if child.is_a? ClassNode
        name = child.fullname.to_s
        first_cls = classes_seen[name]
        if first_cls
          w "Merging class #{name}"
          first_cls.assign_children first_cls.children + child.children
          next # don't add it to new_children
        else
          classes_seen[name] = child
        end
      end
      new_children << child
    end
    assign_children new_children
    return self
  end
end
