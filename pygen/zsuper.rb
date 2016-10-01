class SuperWithoutArgsNode

  def real_gen
    def_node = find_surrounding DefNode
    def_name = def_node.initialize? ? '__init__' : def_node.new_name
    $pygen.write "super().#{def_name}"
    $pygen.paren do
      $pygen.write def_node.argument_names.join ', '
    end
  end
end
