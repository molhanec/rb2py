class ModuleOrPackageNode

  def real_gen
    if contains_other_module?
      $pygen.package(name) {
        gen_topmost_module_import
        gen_imports_for_subpackages
        gen_imports
        gen_children { $pygen.indent }
      }
    else
      $pygen.open_module(name) {
        gen_topmost_module_import
        gen_imports_for_subpackages
        gen_imports
        gen_children { $pygen.indent }
      }
    end
  end

  # Generate import statement for the topmost module
  def gen_topmost_module_import
    topmost = nil
    current = self
    while true
      if current.is_a? ModuleOrPackageNode
        topmost = current.name
      end
      current = current.parent
      unless current
        break
      end
    end
    d "Topmost module for #{self}"
    if topmost
      topmost = $pygen.py_class_name(topmost)
      d "  .. #{topmost}"
      $pygen.write "\nimport #{topmost}"
    else
      d "  .. not found"
    end
  end

  def gen_imports_for_subpackages
    filter_children ModuleOrPackageNode do
      |child|
      $pygen.write "\nimport #{$pygen.py_class_name(child.fullname.to_s)}"
      child.gen_imports_for_subpackages
    end
  end

  def gen_imports
    gen_children RequireNode
    $pygen.write_imports
  end
end


# Helper for translating plain scripts
class MainScriptModuleNode
  def real_gen
    $pygen.open_module 'main' do
      $pygen.indent 'import sys'
      $pygen.indent 'ARGV = sys.argv'
      gen_children { $pygen.nl }
    end
  end
end