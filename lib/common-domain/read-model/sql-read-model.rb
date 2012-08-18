module CommonDomain::ReadModel
  class SqlReadModel < Base
    Log = CommonDomain::Logger.get "common-domain::read-model::sql-read-model"
    
    class SchemaNotInitialized < ::StandardError
      def initialize
        super("Database schema has not been initialized yet.")
      end
    end
    
    class SchemaDefinition
      attr_reader :table_names
      def initialize(connection)
        @connection  = connection
        @datasets    = {}
        @table_names = []
      end
      
      def table(key, name, &block)
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
    
    attr_reader :connection, :schema
    
    def initialize(connection, options = {})
      @options = {
        perform_setup: true
      }.merge! options
      @connection  = connection
      @schema      = SchemaDefinition.new connection
      @initialized = false
      setup if @options[:perform_setup]
    end
    
    def setup
      setup_schema
      prepare_statements
      @initialized = true
    end
    
    def purge!
      Log.warn "Purging all data..."
      ensure_initialized!
      schema.table_names.each do |table_name|
        connection.drop_table table_name
      end
      setup_schema
    end
    
    def ensure_initialized!
      raise SchemaNotInitialized.new unless @initialized
    end
    
    private
      def setup_schema
        self.class.schema_setup.call(schema) if self.class.schema_setup
      end
      
      def prepare_statements
        self.class.statements_preparation.call(schema) if self.class.statements_preparation
      end
    
    class << self
      attr_reader :schema_setup, :statements_preparation
      
      # &block to be called with schema
      def setup_schema(&block)
        @schema_setup = block
      end
      
      # &block to be called with schema
      def prepare_statements(&block)
        @statements_preparation = block
      end
    end
  end
end
