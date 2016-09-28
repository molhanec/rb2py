class RangeExclusiveNode
  def real_gen
    $pygen.write 'range'
    $pygen.paren {
      from.gen
      $pygen.write ', '
      to.gen
    }
  end
end

class RangeInclusiveNode
  def real_gen
    $pygen.write 'range'
    $pygen.paren {
      from.gen
      $pygen.write ', 1 + '
      to.gen
    }
  end
end
