class EigenClassNode

  def fix_eigen_class
    result = []
    for element in elements
      real_fix_eigen_class element, result
    end
    return result
  end

  def real_fix_eigen_class(element, result)
    case element
      when AttributeNode
        result << (AttributeStaticNode.from_attribute element)
      when BeginNode
        for child in element.children
          real_fix_eigen_class child, result
        end
      when DefNode
        result << (DefSingletonNode.from_def element)
      else
        stop! "Unknown eigen class element '#{element}'"
    end
  end
end
