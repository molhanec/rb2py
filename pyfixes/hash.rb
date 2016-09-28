# If we known from static analysis that the target (variable) is a hash, we can generate more succint code

require_relative 'custom_methods_call'

class SendNode < SubexpressionNode

  def pyfix_hash
    return self unless target_class? HashNode
    case message_name
      when 'delete_if' then return self # We are inside DeleteIfNode
      when 'each' then return self # We are inside EachNode
      when 'merge!', 'update' then return pyfix_hash_merge
      when 'values' then return pyfix_hash_values
      else
        if CUSTOM_METHODS_CALL.include? message_name
          self
        else
          stop! "Unknown hash method #{message_name}"
        end
    end
  end

  # merge! => update
  # update => update
  def pyfix_hash_merge
    expect_len 2 # target + one argument
    @message_name = 'update'
    return self
  end

  # In Python 3 values() returns live view.
  # Wrap it to list.
  #   hash.values()
  # ==>
  #   list(hash.values())
  def pyfix_hash_values
    expect_no_arguments
    new_target = make_global_target
    send_node = SendNode.new ruby_node:ruby_node, target:new_target, message_name:'list', arguments:self
    send_node.cls = ArrayNode
    return send_node
  end
end
