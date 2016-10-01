# Shared by StatementList and Class

module LateInserter

  def initialize
    super()
    @late_inserts = [] # this will be inserted into children after each fixing
  end

  def late_insert(before:nil, node:nil)
    stop! "Before (#{before}) or node (#{node}) nil!" if before.nil? or node.nil?
    @late_inserts << {before: before, node: node}
  end

  def fix(fixture)
    result = super
    # while late_insert = @late_inserts.pop
    # Apply in the order late inserts were generated.
    # E.g.
    #   x = (a or b) or c
    # 1. step
    #   @late_inserts = [(_result = a)]
    #   x = (_result if _result else b) or c
    # 2. step
    #   @late_inserts = [(_result = a), (_result = _result if _result else b)]
    #   x = _result if _result else c
    # must became
    #   _result = a
    #   _result = _result if _result else b
    #   x = _result if _result else c
    while late_insert = @late_inserts.shift
      where = children.index late_insert[:before]
      unless where
        stop! "Cannot find location for late insert in statement list", bt:caller
      end
      new_children = late_insert[:node]
      children.insert where, new_children
      if new_children.is_a? Array
        children.flatten!
        new_children.each do
        |child|
          child.parent = self
        end
      else
        new_children.parent = self
      end
    end
    return result
  end
end
