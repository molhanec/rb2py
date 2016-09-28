# String node. The real string is its single children, instance of StringLeafNode
class StringNode
  def real_gen
    value.gen
  end
end


# This represents the real string
class StringLeafNode
  def real_gen
    # Quick hack to escape string
    # see http://stackoverflow.com/questions/8639642/best-way-to-escape-and-unescape-strings-in-ruby
    # escaped_value = value.inspect[1..-2].gsub("'", "\\\\'")
    escaped_value = value.inspect[1..-2]
    if parent.parent.respond_to? 'message_name' and parent.parent.message_name == 'open'
      # Make calls to open() simpler
      escaped_value.gsub! "'", "\\\\'"
      $pygen.write "'#{escaped_value}'"
    else
      escaped_value.gsub! "\\", "\\"*4
      escaped_value.gsub! "'", "\\\\'"
      $pygen.write "rb2py.String.double_quoted('#{escaped_value}')"
    end
  end
end


# Extend standard String class so we can use it in place of real StringNode
class String
  def gen
    $pygen.write to_s
  end
end

