module CommonDomain::ReadModel
  class SqlReadModel < Base
    autoload :Schema, 'common-domain/read-model/sql-read-model/schema'
    
    Log = CommonDomain::Logger.get "common-domain::read-model::sql-read-model"
    
    attr_reader :connection, :schema
    
    def initialize(connection, options = {})
      @options = {
        perform_setup: true
      }.merge! options
      @connection  = connection
      @schema      = Schema.new connection
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
    
    def rebuild_required?
      schema.outdated?
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
