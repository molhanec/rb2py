class ArrayNode < Node

  def real_gen
    # When an array is used as a dictionary key or in exception handler then convert to tuple
    unless parent.is_a? IndexAssignNode or parent.is_a? RescueBodyNode
      $pygen.write '['
      $pygen.gen_comma_separated_list children
      $pygen.write ']'
    else
      # Handle special case
      #   d = {}
      #   d[[1, 2]] = 3
      # because Python's list is (unlike tuple) non-hashable
      $pygen.write '('
      $pygen.gen_comma_separated_list children
      $pygen.write ')'
    end
  end

  def gen_instance_call(message_name, target, &block)
    $pygen.call message_name, target, &block
  end

  def self.gen
    $pygen.write 'list'
  end
end
