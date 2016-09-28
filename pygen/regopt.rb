# Regular expression flags

class RegoptNode

  REGEXP_FLAG_MAP = {
    'i' => 're.IGNORECASE',

    # Dot matches newline
    'm' => 're.DOTALL',

    # Allow whitespace and comments inside regexps
    'x' => 're.VERBOSE',

    # Regexp encoding flags, ignore
    'e' => nil, 'n' => nil, 's' => nil, 'u' => nil,

    # Don't define this, we cannot handle them
    # o: ???
  }

  def real_gen
    python_flags = []
    for flag in children
      flag.expect_symbol
      # Throws an exception if unknown flag
      python_flag = REGEXP_FLAG_MAP.fetch flag.value
      python_flags << python_flag if python_flag
    end
    $pygen.write "flags=#{python_flags.join ' + '}" if python_flags.size > 0
  end
end
