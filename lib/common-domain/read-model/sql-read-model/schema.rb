class CommonDomain::ReadModel::SqlReadModel
  class SchemaNotInitialized < ::StandardError
    def initialize
      super("Database schema has not been initialized yet.")
    end
  end

  class Schema
    attr_reader :table_names
    def initialize(connection)
      @connection  = connection
      @datasets    = {}
      @table_names = []
    end

    def table(key, name, &block)
      raise "Table name can not be nil for key: #{key}" if name.nil?
      unless @connection.table_exists? name
        Log.debug "Creating table: #{name}"
        @connection.create_table(name, &block)
      end
      @table_names << name
      @datasets[key] = @connection[name]
      nil
    end

    def respond_to?(sym)
      return true if @datasets.key?(sym)
      super(sym)
    end

    def method_missing(meth, *args, &blk)
      return @datasets[meth] if @datasets.key?(meth)
      super(meth, *args, &blk)
    end
  end
end