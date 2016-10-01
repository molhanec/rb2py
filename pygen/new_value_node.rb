class NewValueNode
  def real_gen
    if parent.is_a? ClassOrModuleNode
      $pygen.indent value
    else
      $pygen.write value
    end
  end
end

