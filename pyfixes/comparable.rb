# Translates Comparable mixin into functools.total_ordering

class ClassNode

  def decorators
    @decorators ||= []
  end
end


class IncludeNode

  def pyfix_comparable
    return self unless class_name == 'Comparable'
    parent.expect_class ClassNode
    parent.decorators << 'functools.total_ordering'
    $pygen.imports << 'functools'
    return PythonComparableNode.new ruby_node
  end
end


# Implements <, == and is_between using _cmp() method which is translated <=> operator
class PythonComparableNode < Node

  def real_gen
    $pygen.method '__lt__' do
      $pygen.argument 'other'
      $pygen.body do
        $pygen.indent 'return self._cmp(other) < 0'
      end
    end
    $pygen.method '__eq__' do
      $pygen.argument 'other'
      $pygen.body do
        $pygen.indent 'return self._cmp(other) == 0'
      end
    end
    $pygen.method 'is_between' do
      $pygen.argument 'min'
      $pygen.argument 'max'
      $pygen.body do
        $pygen.indent 'return min <= self <= max'
      end
    end
  end
end
