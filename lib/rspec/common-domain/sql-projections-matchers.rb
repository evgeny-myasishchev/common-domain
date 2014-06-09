class HaveTableMatcher
  
  # block here is passed if {|table| } syntax is used
  def initialize(table_name, &block)
    @table_name = table_name.to_sym
    @block = block
  end

  # block here is passed if do |table| end syntax is used
  def matches?(actual, &block)
    @actual = actual
    result = @actual.table_exists?(@table_name)
    the_block = block || @block
    the_block.call(@actual[@table_name]) if result && the_block
    result
  end

  def failure_message
    "expected #{@actual} to have table #{@table_name}"
  end

  def failure_message_when_negated
    "expected #{@actual} not to have table #{@table_name}"
  end
end

# Have table matcher
# expect(connection).to have_table(:empllyees) do |table|
#   expect(table).to have_column(:id, primary_key: true, allow_null: false)
#   expect(table).to have_column(:name, allow_null: false)
# end
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
  
  def failure_message
    but = @column.nil? ? "but no column found" : "but was #{@column} (specified only attribs are matched)"
    "table #{@table_name} expected to have column [#{@column_name}, #{@attribs}] #{but}"
  end
  
  def failure_message_when_negated
    "table #{@table_name} expected not to have column [#{@column_name}, #{@attribs}]"
  end
end