
$EXTERNAL_CLASSES = {
  # Standard Python classes
  'Array' => 'list',
  'Hash' => 'rb2py.OrderedDict',
  'Range' => 'range',

  # Exceptions
  'ArgumentError' => 'ValueError',
  'NoMethodError' => 'Exception',
  'StandardError' => 'Exception',

  # Number ABCs
  'Fixnum' => 'rb2py.numbers.Integral',
  'Integer' => 'rb2py.numbers.Integral',
  'Numeric' => 'rb2py.numbers.Number',

  # Others
  'Regexp' => 'rb2py.create_regexp',
  'Regexp::MULTILINE' => 're.DOTALL',
  'IO::SEEK_CUR' => 'rb2py.SEEK_CUR',
  'IO::SEEK_END' => 'rb2py.SEEK_END',
  'IO::SEEK_SET' => 'rb2py.SEEK_SET',
  'String' => 'rb2py.String',
  'StringIO' => 'rb2py.StringIO',
  'Time' => 'rb2py.Time',

  # for ResolveAncestor#real_resolve_ancestor
  'Comparable' => 'Comparable',
  'Enumerable' => 'Enumerable',

  # Actually plain constants
  'ENV' => 'rb2py.env',

}

def external_class(class_name, default:nil)
  stripped_class_name = class_name.sub(/^rb2py::/,'') # strip optional :: (constant name base) on the begging
  new_name = $EXTERNAL_CLASSES[stripped_class_name]
  unless new_name
    first_part, *rest = stripped_class_name.split '::'
    new_name = $EXTERNAL_CLASSES[first_part]
    if new_name
      new_name = [new_name, *rest].join '::'
    end
  end
  if new_name
    return new_name
  else
    return class_name
  end
end
