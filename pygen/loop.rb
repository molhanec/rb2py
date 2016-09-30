class LoopNode
  def real_gen
    $pygen.while 'True', statements
  end
end