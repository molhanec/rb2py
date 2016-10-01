class SendNode

  def real_gen
    # if it is attribute without an explicit getter
    if target.has_attribute? message_name and !target.has_method? message_name
      target.gen
      $pygen.write "._#{message_name}"
    else
      if target.respond_to? :cls and target.cls and target.cls.respond_to? :gen_instance_call
        target.cls.gen_instance_call message_name, target do
          gen_children { $pygen.write ', ' }
        end
      else
        $pygen.call message_name, target do
          gen_children { $pygen.write ', ' }
        end
      end
    end
  end
end
