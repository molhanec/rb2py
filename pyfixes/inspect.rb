#   object.inspect()
# ==>
#   repr(object)

class SendNode
  def pyfix_inspect
    if message_name == 'inspect'
      expect_no_arguments
      return SendNode.new ruby_node:ruby_node, target:make_global_target, message_name:'repr', arguments:[self.target]
    end
    return self
  end
end
