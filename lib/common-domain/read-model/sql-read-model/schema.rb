class CommonDomain::ReadModel::SqlReadModel
  class SchemaNotInitialized < ::StandardError
    def initialize
      super("Database schema has not been initialized yet.")
    end
  end

  class Schema
    attr_reader :table_names
    
    def initialize(connection, options, &block)
      @options = {
        version: 0,
        identifier: nil
      }.merge! options
      raise ":identifier must be provided. Schema can not be initialized without an identifier." if @options[:identifier].nil?
      
      @connection  = connection
      @datasets    = {}
      @table_names = []
      @block       = block
    end
    
    def setup_required?
      
    end
    
    def setup
      @block.call(self)
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
