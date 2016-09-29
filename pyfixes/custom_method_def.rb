# Translating method definitions

CUSTOM_METHODS_DEF = {
  '<<' => 'append',
  '>=' => '__ge__',
  '<=>' => '_cmp',
  '[]' => '__getitem__',
  '[]=' => '__setitem__',
  'each' => '__iter__',
  'eql?' => '__eq__',
  'for' => 'for_', # Python keyword
  'hash' => '__hash__',
  'to_f' => '__float__',
}


class DefNode
  def pyfix_custom_methods_def
    @new_name = CUSTOM_METHODS_DEF.fetch new_name, new_name
    return self
  end
end
