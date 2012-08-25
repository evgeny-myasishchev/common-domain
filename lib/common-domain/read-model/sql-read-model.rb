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
      setup_schema(schema)
      prepare_statements(schema)
      @initialized = true
    end
    
    def purge!
      Log.warn "Purging all data..."
      ensure_initialized!
      schema.table_names.each do |table_name|
        connection.drop_table table_name
      end
      setup_schema(schema)
    end
    
    def ensure_initialized!
      raise SchemaNotInitialized.new unless @initialized
    end
    
    protected
      def setup_schema(schema)
      end
      
      def prepare_statements(schema)
      end
    
    class << self
      # &block to be called with schema
      def setup_schema(options = {}, &block)
        options = {
          version: 0
        }.merge! options
        define_method(:setup_schema, block)
        protected :setup_schema
      end
      
      # &block to be called with schema
      def prepare_statements(&block)
        define_method(:prepare_statements, block)
        protected :setup_schema
      end
    end
  end
end
