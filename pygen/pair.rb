class PairNode
  def real_gen
    # Wrap key-value pair inside tuple
    $pygen.paren {
      key.gen
      $pygen.write ', '
      value.gen
    }
    $pygen.write ', '
  end
end