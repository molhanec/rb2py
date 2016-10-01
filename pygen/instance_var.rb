class InstanceVariableNode
  def real_gen
    $pygen.write "self._#{name}"
  end
end
