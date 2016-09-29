class DefNode

  def real_gen

    # For some reason there are module functions in Prawn which have same name as a class.
    # They just instantiate the class using Class.new. We just skip them, because in Python the instantiation
    # is already done using Class() syntax.
    if parent.is_a? ModuleOrPackageNode
      self.true_method = false
      parent.all_classes do
        |cls|
        if cls.name == new_name
          w "Module function #{new_name} has same name as a module class. Skipping…"
          return
        end
      end
    end

    # Method decorators
    decorators = []

    # Generate decorator for functions containing block_given? test and not explicit block parameter
    if block_given_test and !block_argument
      stop! "Implementation changed!"
    end

    if static_method?
      decorators << '@staticmethod'
    end

    if contains_block_with_return?
      decorators << '@rb2py.contains_block_with_return'
    end

    $pygen.method new_name, true_method, decorators do

      arguments.gen

      $pygen.body do

        # Variables from outer scope referenced by closures
        for nonlocal in nonlocals
          $pygen.indent "nonlocal #{nonlocal}"
        end

        # This array emulates $1, $2 etc, regexp match group variables
        # Although they start with $, they are actually method-local
        if regexp_captures
          $pygen.indent "rb2py_regexp_captures = []"
        end

        # In Ruby local variables can be used before assignment, they have implicit nil
        for local_var in local_vars
          $pygen.indent "#{local_var} = None" unless argument_names.include? local_var
        end

        # We require the block parameter to have 'block' name so we can call it by keyword.
        # If it had different name, assign it to that name.
        if block_argument and block_argument.name != 'block'
          if argument_names.include? 'block'
            stop! "There is block argument, but a different argument already uses 'block' name!"
          end
          $pygen.indent "#{block_argument.name} = block"
        end

        body.gen
      end
    end

    # Generate additional methods
    case new_name

      # For copy constructor generate also Python style shallow copy
      when 'initialize_copy'
        $pygen.method '__copy__' do
          $pygen.body do
            cls = find_surrounding ClassNode
            $pygen.indent "new_obj = #{cls.name}()"
            $pygen.indent "new_obj.initialize_copy(self)"
            $pygen.indent "return new_obj"
          end
        end

      # Wrap str and repr, which will convert rb2py.String into plain Python string
      when 'to_s'
        $pygen.method '__str__' do
          $pygen.body do
            $pygen.indent "return str(self.to_s())"
          end
        end
      when 'inspect'
        $pygen.method '__repr__' do
          $pygen.body do
            $pygen.indent "return str(self.inspect())"
          end
        end
    end
  end

  # Convert eigenmethods of class to static methods
  def static_method?
    is_a? DefSingletonNode and parent.is_a? ClassNode
  end
end

# Constructor method
class InitializeNode
  def real_gen
    $pygen.method '__init__' do
      arguments.gen
      $pygen.body do

        # Allow class to initialize attributes
        # see ClassNode::gen_init for details
        yield

        body.gen
      end
    end
  end
end
