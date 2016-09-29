# Method definition

class Node

  def fix_def
    return self unless symbol? 'def'
    expect_len 3 # name, argument list, body (single or inside "begin")
    name = first_child.load_name
    arguments = second_child
    body = third_child.make_statement_list
    cls = name == 'initialize' ? InitializeNode : NoInitializeDefNode
    cls.new @ruby_node, name, arguments, body
  end

  def inside_initialize?
    (find_surrounding DefNode).initialize?
  end
end


class DefNode < Node

  attr_accessor :true_method # False for plain functions
  attr_accessor :regexp_captures # Does the method need regexp captures?
  attr_reader :new_name

  alias arguments first_child
  alias body second_child

  def argument_names
    arguments.argument_names
  end

  # Is this function created for block emulation?
  def block_emulation?
    false
  end

  def initialize(ruby_node, name, arguments, body)
    super()
    @true_method = true
    @regexp_captures = false
    @ruby_node = ruby_node
    @new_name = @name = name
    assign_children [arguments, body]
  end

  def to_s
    "Def(#@name)"
  end

  def block_argument
    arguments.block_argument
  end

  # Looks if there is local variable var_name assignment between the nodes
  def real_local_variable?(nodes, var_name)
    for node in nodes
      if node.is_a? AssignLocalVarNode and var_name == node.name
        # Standard local variables created by an assignment
        return true
      elsif node.is_a? ArgumentListNode and node.argument_names.include? var_name
        # Arguments create also local variables
        return true
      elsif !node.is_a? DefNode
        if real_local_variable? node.children, var_name
          return true
        end
      end
    end
    return false
  end

  # Does this method have var_name as a local variable?
  # I.e. it is assigned?
  # If search_parent_defs is true it also looks for parent defs.
  def local_variable?(var_name, search_parent_defs:false)

    # _result is never standard local variable
    if var_name == '_result'
      return false
    end

    if real_local_variable? children, var_name
      return true
    end

    # Parents
    if search_parent_defs
      parent = self
      while parent = parent.parent
        if parent.is_a? DefNode
          if parent.real_local_variable? parent.children, var_name
            return true
          end
        end
      end
    end
    return false
  end
end


# Method which is not initialize()
class NoInitializeDefNode < DefNode
  attr_accessor :block_given_test
end


# Method used for block emulation
class BlockEmulationDefNode < NoInitializeDefNode

  attr_accessor :contains_control_expression

  def block_emulation?
    true
  end
end


# initialize() method
class InitializeNode < DefNode

  def initialize?
    true
  end
end


class Node
  def initialize?
    false
  end
end
