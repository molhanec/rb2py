class IRangeNode
  def real_gen
    $pygen.call 'range' do
      from.gen
      $pygen.write ', '
      to.gen; $pygen.write ' + 1'
    end
  end
end