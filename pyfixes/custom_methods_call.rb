# These methods are translated into rb2py functions.

# Format
#   ruby_method_name => [argument_counts]
# If argument count is :n, it accepts any count of arguments.
# If it includes :global, the original target object is not passed to the function, otherwise it is passed as a first
# parameter.
CUSTOM_METHODS_CALL = {
    'abs' => [0],
    'any?' => [0],
    'arity' => [0],
    'Array' => [:global, 1],
    'chr' => [0],
    'class' => [0],
    'collect' => [1],
    'compact' => [0],
    'concat' => [1],
    'const_get' => [1],
    'count' => [0, 1],
    'cmp' => [1],
    'delete' => [1],
    'downcase' => [0],
    'each_index' => [0],
    'each_value' => [1],
    'empty?' => [0],
    'even?' => [0],
    'extend' => [1],
    'fetch' => [2],
    'first' => [0],
    'flat_map' => [1],
    'flatten' => [0],
    'Float' => [:global, 1],
    'freeze' => [0],
    'has_key?' => [1],
    'hash' => [0],
    'include?' => [1],
    'index' => [1],
    'insert' => [2],
    'instance_variable_set' => [2],
    'instance_of?' => [1],
    'Integer' => [:global, 1],
    'invert' => [0],
    'join' => [0, 1],
    'key?' => [1],
    'keys' => [0],
    'last' => [0],
    'length' => [0],
    'map' => [1, 2],
    'max' => [0],
    'merge' => [1],
    'merge!' => [1],
    'min' => [0],
    'name' => [0],
    'nonzero?' => [0],
    'object_id' => [0],
    'odd?' => [0],
    'p' => [:n],
    'pack' => [1],
    'pos' => [0],
    'print' => [:n, :global],
    'printf' => [:n],
    'pop' => [0],
    'product' => [1],
    'push' => [1],
    'puts' => [:n, :global],
    'rand' => [:global, 1],
    'replace' => [1],
    'respond_to?' => [1],
    'reverse' => [0],
    'reverse!' => [0],
    'rewind' => [0],
    'round' => [1],
    'send' => [:n],
    'shift' => [0],
    'size' => [0],
    'sort' => [0],
    'step' => [2],
    'String' => [:global, 1],
    'succ!' => [0],
    'times' => [0],
    'to_a'=> [0],
    'to_f' => [0],
    'to_i' => [0, 1],
    'to_s' => [0, 1],
    'to_sym' => [0],
    'uniq' => [0],
    'unpack' => [1],
    'upcase' => [0],
    'update' => [1],
    'valid_encoding?' => [0],
    'warn' => [:global, 1],
    'zero?' => [0],
    'zip' => [1],
}


#   operator => python_method_name
CUSTOM_OPERATORS = {
    '<<' => 'append',
    '<=>' => 'cmp',
    'for' => 'for_', # Python keyword
}


class SendNode
  def pyfix_custom_methods_call

    # File class methods
    if message_name == 'exist?' and target.name == 'File'
      return pyfix_file_exist
    end
    if message_name == 'foreach' and target.name == 'File'
      return pyfix_file_foreach
    end

    # remove 'extend Forwardable'
    if message_name == 'extend' and target.self? and children.size == 2 and children[1].name == 'Forwardable'
      return []
    end

    name = CUSTOM_OPERATORS.fetch message_name, message_name
    custom_method = CUSTOM_METHODS_CALL[name]
    if custom_method
      if custom_method.include? argument_count
        name = method_new_name(name)
        name = "#{name}#{argument_count}"
      elsif custom_method.include?(:strip)
        # Strip arguments
        return make_rb2py_call method_new_name(name), target
      elsif not custom_method.include?(:n)
        w1 "No custom method for #{message_name} with #{argument_count} parameters"
        name = method_new_name(name)
        @message_name = name
        return self
      end
      global = custom_method.include? :global # Kernel method => ignore target
      arguments = (global or target.name == 'rb2py') ? children[1..-1] : children
      return make_rb2py_call name, *arguments
    else
      @message_name = name
      return self
    end
  end

  def pyfix_call
    if message_name == 'call'

      # Search to first non block-emulation method to find if we are in __iter__() or not
      current = self
      while current = current.parent
        if current.is_a? DefNode
          if current.iteration_node?
            return PythonYield.new children[1..-1] # Keep yield in __iter__() methods
          end
          break unless current.block_emulation?
        end
      end

      return make_rb2py_call message_name, *children
    end
    return self
  end

  def pyfix_file_exist
    make_rb2py_call 'file_exist', *children[1..-1] # strip target
  end

  def pyfix_file_foreach
    make_rb2py_call 'file_foreach', *children[1..-1] # strip target
  end
end


class PythonYield < Node

  def initialize(children)
    super(nil)
    assign_children children
  end

  def real_gen
    $pygen.write 'yield '
    $pygen.gen_comma_separated_list children
  end

  def get_result
    self
  end

  def to_s
    "PythonYield"
  end
end
