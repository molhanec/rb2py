class MathNode

  def real_gen
    unless ['cos', 'log', 'sin', 'sqrt'].include? function_name
      stop! "Unknown math function #{function_name}", 'MathNode.real_gen'
    end
    $pygen.call function_name, 'math' do
      gen_children { $pygen.write ', ' }
    end
  end
end
