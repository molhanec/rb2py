# We basically remove Enumerable mixin, because what is method in Ruby (e.g. collection.map {... })
# is either a global function in Python (e.g. map(function, collection)), or is our custom function of rb2py module.
# So it just relies on the fact, that each method is translated correctly into __iter__ method.

class IncludeNode

  def pyfix_include_enumerable
    if class_name == 'Enumerable'
      return [] # remove itself
    else
      return self
    end
  end
end
