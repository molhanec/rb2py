class SelfNode

  def real_gen
    self_target = find_surrounding ClassNode, ModuleOrPackageNode
    case self_target
      when ClassNode
        begin
          def_node = find_surrounding DefNode
        rescue
          w1 'Unknown self'
          $pygen.write 'UNKNOWN_SELF'
          return
        end
        unless def_node.static_method?
          $pygen.write 'self'
        else
          $pygen.write $pygen.py_class_name(self_target.fullname.to_s)
        end
      when ModuleOrPackageNode
        $pygen.write $pygen.py_class_name(self_target.fullname.to_s)
      else
        stop! "Unknown self target #{self_target}"
    end
  end
end
