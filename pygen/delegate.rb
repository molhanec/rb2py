class DelegateNode
  def real_gen
    $pygen.method(@message_name) {
      $pygen.argument '*args'
      $pygen.body {
        $pygen.indent "return self.#{target.value}().#{@message_name}(*args)"
      }
    }
  end
end