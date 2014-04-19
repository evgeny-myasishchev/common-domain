module SchemaHelper
  def check_column(connection, table_name, column_name, &block)
    columns = connection.schema(table_name)
    col     = columns.detect { |c| c[0] == column_name }
    col.should_not be_nil, "Column '#{column_name}' not found."
    yield(col[1])
  end
end