# Make list of external (non-enclosed) classes and modules on which this class depends,
# i.e. either inherits from them or includes them.

class ClassNode

  attr_reader :dependencies

  def fix_make_dependencies_list
    @dependencies = []

    # Dependencies of enclosed classes
    filter_children ClassNode do
      |cls|
      for dependency in cls.dependencies
        unless enclosed_classes.include? dependency
          @dependencies << dependency
        end
      end
    end

    # Ancestor dependency
    if ancestor and not(enclosed_classes.include? ancestor)
      @dependencies << ancestor
    end

    # Dependency on included modules
    filter_children IncludeNode do
      |include_node|
      unless enclosed_classes.include? include_node.fullname
        @dependencies << include_node.fullname
      end
    end

    d "Class '#{fullname}' has these external dependencies: '#{dependencies_to_s}'"
    return self
  end

  def dependencies_to_s
    dependencies.map{ |fullname| fullname.to_s }.sort.join ', '
  end
end
