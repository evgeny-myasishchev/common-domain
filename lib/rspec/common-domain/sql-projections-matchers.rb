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

RSpec::Matchers.define :have_column do |column_name, attribs|
  match do |actual|
    @column_name = column_name
    @attribs = attribs
    if actual.opts[:from].length != 1
      raise "DataSet should be based on a single table."
    end
    @table_name = actual.opts[:from][0]
    columns = actual.db.schema(@table_name)
    @column = columns.detect { |c| c[0] == column_name }
    if @column.nil?
      false
    else
      column_attribs = @column[1]
      attribs_ok = true
      attribs.each_pair { |name, val| 
        unless column_attribs[name] == val
          attribs_ok = false
          break
        end
      }
      attribs_ok
    end
  end
  
  def failure_message_for_should
    but = @column.nil? ? "but no column found" : "but was #{@column} (specified only attribs are matched)"
    "table #{@table_name} expected to have column [#{@column_name}, #{@attribs}] #{but}"
  end
  
  def failure_message_for_should_not
    "table #{@table_name} expected not to have column [#{@column_name}, #{@attribs}]"
  end
end