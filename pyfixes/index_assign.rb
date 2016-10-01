class IndexAssignNode

  def index
    unless indices.size > 1
      return indices[0]
    else
      stop! "Index assignment allowed only for single index in Python"
    end
  end

  def pyfix_index_assign
    unless value.missing? and indices.size == 1
      # unless we are part of multiple assignment
      return make_rb2py_call 'set_index', *children
    end
    return self
  end
end
