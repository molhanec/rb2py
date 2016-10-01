
#   method { break value }
# ==>
#   def _block_X():
#     raise rb2py.ReturnFromBlock(value)
#   method(_block_X)
class BreakNode
  def pyfix_translate_control_expressions_in_block
    def_node = find_surrounding DefNode
    if def_node.block_emulation?
      def_node.contains_block_with_return = true
      return RaiseNode.new ruby_node, children, class_name:'rb2py.ReturnFromBlock'
    end
    return self
  end
end


#   method { next value }
# ==>
#   def _block_X():
#     return value
#   method(_block_X)
class NextNode
  def pyfix_translate_control_expressions_in_block
    def_node = find_surrounding DefNode
    if def_node.block_emulation?
      return ReturnNode.new ruby_node, children
    end
    return self
  end
end
