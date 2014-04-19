class HaveTableMatcher
  def initialize(table_name, &block)
    @table_name = table_name
    @block = block
  end

  def matches?(actual)
    @actual = actual
    result = @actual.table_exists?(@table_name)
    @block.call(@actual[@table_name]) if result && @block
    result
  end

  def failure_message_for_should
    "expected #{@actual} to have table #{@table_name}"
  end

  def failure_message_for_should_not
    "expected #{@actual} not to have table #{@table_name}"
  end
end

def have_table(table_name, &block)
  HaveTableMatcher.new table_name, &block
end