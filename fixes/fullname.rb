class Fullname

  SEPARATOR = '::'

  attr_reader :parts

  def initialize(str_or_array)
    if str_or_array.nil?
      @parts = []
    elsif str_or_array.is_a? Fullname
      @parts = []
      for part in str_or_array.parts
        @parts << part.dup
      end
    elsif str_or_array.respond_to? :to_ary
      # it is an array?
      @parts = str_or_array.to_ary
    elsif str_or_array.respond_to? :to_str
      # it is a string?
      @parts = str_or_array.to_str.split SEPARATOR
    else
      raise "Fullname constructor parameter must be either a string or an array. Got #{str_or_array.inspect}"
    end
  end

  def valid?
    parts.size > 0
  end

  def to_s
    to_a.join SEPARATOR
  end

  def to_a
    parts
  end

  def last_part
    parts.last
  end

  def prepend(part)
    parts.unshift part
  end

  def append(part)
    parts << part
  end

  def ==(other)
    if other.is_a? String
      return to_s == other
    end
    parts == other.parts
  end

  def +(other)
    result = Fullname.new self
    case other
      when String
        result.append other
      else
        stop! "Unknown type #{other.class} for Fullname#+"
    end
    return result
  end
end
