module SchemaHelper
  def check_column(connection, table_name, column_name, &block)
    columns = connection.schema(table_name)
    col     = columns.detect { |c| c[0] == column_name }
    expect(col).not_to be_nil, "Column '#{column_name}' not found."
    yield(col[1])
  end
end