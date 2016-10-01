require_relative '../pyfixes/custom_methods_call'

class AliasNode
  def real_gen
    new_name_s = new_fixed_name
    if CUSTOM_OPERATORS.include? new_name_s
      new_name_s = CUSTOM_OPERATORS[new_name_s]
    end
    $pygen.indent "#{new_name_s} = #{old_fixed_name}"
  end
end
