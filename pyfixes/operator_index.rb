# Indexing convert to get_index() call unless it is slicing
class IndexNode

  def pyfix_op_index
    unless indices[0].is_a? PythonSliceNode
      if indices.size > 1
        make_rb2py_call 'get_indices', *children
      else
        make_rb2py_call 'get_index', *children
      end
    else
      self
    end
  end
end
