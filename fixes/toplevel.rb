# Sole purpose of this class is to act like a holder to the real root node.
# It makes it easier to run fixtures on the root node.
class TopLevelNode < Node

  # Real root node
  attr_reader :root

  def initialize(real_root)
    super()
    @children = [real_root]
  end

  FIXES = [
    :fix_gvar,
    :fix_sclass,
    :fix_nth_ref,
    :fix_next,
    :fix_resbody,
    :fix_rescue,
    :fix_kwbegin,
    :fix_cvar,
    :fix_cvasgn,
    :fix_super,
    :fix_zsuper,
    :fix_ensure,
    :fix_break,
    :fix_true,
    :fix_until,
    :fix_while,
    :fix_regopt,
    :fix_regexp,
    :fix_yield,
    :fix_splat,
    :fix_block_pass,
    :fix_masgn,
    :fix_mlhs,
    :fix_cbase,
    :fix_when,
    :fix_case,
    :fix_erange,
    :fix_irange_in_begin,
    :fix_irange,
    :fix_nil,
    :fix_or_assign,
    :fix_op_asgn,
    :fix_defined,
    :fix_int,
    :fix_float,
    :fix_false,
    :fix_and,
    :fix_or,
    :fix_array,
    :fix_hash,
    :fix_pair,
    :fix_lvar,
    :fix_ivar,
    :fix_return,
    :fix_str,
    :fix_sym,
    :fix_alias,
    :fix_lvasgn,
    :fix_dstr,
    :fix_dsym,
    :fix_const,
    :fix_self,
    :fix_if,
    :fix_ivasgn,
    :fix_arg,
    :fix_restarg,
    :fix_optarg,
    :fix_blockarg,
    :fix_args,
    :fix_send,
    :fix_block,
    :fix_block_calls,
    :fix_def,
    :fix_defs,
    :fix_casgn,
    :fix_begin,
    :fix_resolve_ancestor,
    :fix_make_enclosed_class_list,
    :fix_make_dependencies_list,
    :fix_local_assignment,
    :fix_eigen_class,
    :fix_attribute, # depends on fix_eigen_class
    :fix_resolve_self,
    :fix_class_reference,
  ]

  def run_fixes
    for fix in FIXES
      d "Fixing #{fix}"
      $single_fix_was_run = 0
      self.fix fix
      if $single_fix_was_run == 0
        w "Fix #{fix} was not run for any node"
      end
    end
  end

  def all(cls, &block)
    real_all cls, &block
  end

  def root
    expect_len 1
    child
  end

  def merge_modules
    change = true
    while change
      d "Merging modules"
      change = false
      unique_modules = {}
      filter_recursive(children, ModuleOrPackageNode) do
        |mod|
        unique_mod = unique_modules[mod.fullname.to_s]
        if unique_mod
          d "Merging #{mod.fullname}"
          # assign children of the second module to the first
          unique_mod.assign_children unique_mod.children + mod.children
          # and remove the second module from tree
          mod.parent.children.delete mod
          # restart the merging
          change = true
          break
        else
          unique_modules[mod.fullname.to_s] = mod
        end
      end
    end
  end

  def merge_classes
    change = true
    while change
      d "Merging classes"
      change = false
      unique_classes = {}
      filter_recursive(children, ClassNode) do
        |cls|
        unique_cls = unique_classes[cls.fullname.to_s]
        if unique_cls
          d "Merging #{cls.fullname}"
          # assign children of the second class to the first
          unique_cls.assign_children unique_cls.children + cls.children
          # and remove the second class from tree
          cls.parent.children.delete cls
          # restart the merging
          change = true
          break
        else
          unique_classes[cls.fullname.to_s] = cls
        end
      end
    end
  end

  def toplevel
    self
  end
end
