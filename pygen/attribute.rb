class AttributeNode

  def real_gen
    cls_or_module = find_surrounding ClassOrModuleNode
    if cls_or_module.is_a? ModuleOrPackageNode
      # Variable on the module level, don't prefix with self
      $pygen.binop "_#{name}", '=', 'None'
    else
      $pygen.binop "self._#{name}", '=', 'None'
    end
  end

end