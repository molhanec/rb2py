class ArgumentListNode
  def real_gen(&block)
    gen_children &block
  end
end


class ArgumentNode
  def real_gen
    stop! 'abstract'
  end
end


# Positional argument without default value
class SimpleArgumentNode
  def real_gen
    $pygen.argument name
  end
end


# Catch-all argument *args
class RestArgumentNode
  def real_gen
    $pygen.argument "*#{name}"
  end
end


# Positional argument with default value
class OptionalArgumentNode
  def real_gen
    $pygen.argument name, default_value
  end
end


# Block argument &block
class BlockArgumentNode
  def real_gen
    # parent is ArgumentList, its parent is Def
    def_node = parent.parent
    def_node.expect_class DefNode

    # Do nothing for __iter__. That is used with 'yield' or 'yield from'.
    $pygen.argument 'block', 'rb2py.NO_BLOCK' unless def_node.new_name == '__iter__'
  end
end
