class TopLevelNode

  PYTHON_FIXES = %i[
    pyfix_class_extract
    pyfix_class_flatten
    pyfix_class_reorder
    pyfix_class

    pyfix_global_variable
    pyfix_opt_arg
    pyfix_super
    pyfix_assign_local_var
    pyfix_each_with_object
    pyfix_find
    pyfix_partition
    pyfix_nth_ref
    pyfix_custom_block
    pyfix_kwbegin
    pyfix_delete_if
    pyfix_hash_block
    pyfix_ancestor_name
    pyfix_index_assign
    pyfix_include_enumerable
    pyfix_raise
    pyfix_math
    pyfix_or_assign
    pyfix_op_assign
    pyfix_instantiation
    pyfix_encoding
    pyfix_regexp
    pyfix_comparable
    pyfix_range_to_slice
    pyfix_inspect
    pyfix_subexpression
    pyfix_case
    pyfix_hash
    pyfix_array
    pyfix_call
    pyfix_any
    pyfix_open
    pyfix_gsub
    pyfix_sort
    pyfix_map
    pyfix_map_in_place
    pyfix_select
    pyfix_detect
    pyfix_inject
    pyfix_custom_methods_call
    pyfix_custom_methods_def
    pyfix_shallow_copy
    pyfix_deep_copy
    pyfix_defined
    pyfix_op_index_in_assign
    pyfix_op_index
    pyfix_def
    pyfix_yield
    pyfix_block_given_test
    pyfix_ternary
    pyfix_and_or

    pyfix_send_as_default_argument
    pyfix_block_emulation_nonlocals
    pyfix_translate_control_expressions_in_block
    pyfix_contains_block_with_return
    pyfix_blockpass
    pyfix_method_rename
  ]

  def run_python_fixes
    for fix in PYTHON_FIXES
      d "Fixing #{fix}"
      $single_fix_was_run = 0
      self.fix fix
      if $single_fix_was_run == 0
        w "Fix #{fix} was not run for any node"
      end
    end
  end
end


class Node

  def make_custom_target(target_name)
    NewValueNode.new(nil, target_name)
  end

  def make_custom_target_call(target, name, *args)
    target = make_custom_target(target) unless target.is_a? Node
    args = args.map do |arg|
      (arg.is_a? Node) ? arg : (NewValueNode.new nil, arg)
    end
    result = SendNode.new ruby_node:ruby_node, target:target, message_name:name, arguments:args
    return result
  end

  def make_rb2py_target
    make_custom_target 'rb2py'
  end

  def make_rb2py_call(name, *args)
    make_custom_target_call make_rb2py_target, name, *args
  end

  def make_global_call(name, *args)
    make_custom_target_call make_global_target, name, *args
  end
end
