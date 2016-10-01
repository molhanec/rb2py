class StatementListNode
  def real_gen
    for child in children
      $pygen.statement child
    end
  end
end