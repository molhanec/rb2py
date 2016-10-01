class NilTestNode

  def real_gen
    target.gen
    $pygen.write ' is None'
  end
end