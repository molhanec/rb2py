
class Node
  def make_setter_name(attribute_name)
    "_set_#{attribute_name}"
  end

  # Keep in sync with rb2py/__init__.py send1() function
  def method_new_name(name)
    stripped_name = name[0..-2]
    case
      when name.end_with?('?')
        return stripped_name if stripped_name.start_with? 'has_' or stripped_name.start_with? 'can_'
        return "is_#{stripped_name}"
      when name.end_with?('!')
        return "beware_#{stripped_name}"
      when name.end_with?('=')
        return make_setter_name stripped_name
    end
    return name # no change
  end
end


class NoInitializeDefNode < DefNode

  def pyfix_method_rename

    # if the method wasn't already renamed
    unless new_name != name

      # generated new name
      @new_name = method_new_name name

      # if the name changed then check for name clash
      if new_name != name
        cls = parent
        cls.defs.any? do
          | method |
          if method.name == new_name
            stop! "Cannot rename method #{name}. #{new_name} already exists."
          end
        end
      end
    end
    self
  end
end


class SendNode

  def pyfix_method_rename
    @message_name = method_new_name message_name
    return self
  end
end


class DelegateNode

  def pyfix_method_rename
    @message_name = method_new_name delegate.value
    return self
  end
end


class AliasNode

  attr_reader :old_fixed_name, :new_fixed_name

  def pyfix_method_rename
    @old_fixed_name = method_new_name old_name.value
    @new_fixed_name = method_new_name new_name.value
    return self
  end
end
