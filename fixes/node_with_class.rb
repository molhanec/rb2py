module NodeWithClass

  attr_reader :cls

  def initialize
    super()
    @cls = nil
  end

  def cls=(cls)

    if cls.nil?
      msg = "nil passed as a class for #{self}"
      d msg
      return
    end

    if @cls.nil? or @cls == cls
      @cls = cls
    else
      d "Class of (#{self}) is already set to (#{@cls}), new value (#{cls})"
    end
  end

  def class_name
    cls.nil? ? '???' : cls
  end

end
