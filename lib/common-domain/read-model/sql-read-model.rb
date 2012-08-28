module CommonDomain::ReadModel
  class SqlReadModel < Base
    autoload :DatasetsRegistry, 'common-domain/read-model/sql-read-model/datasets-registry'
    autoload :Schema, 'common-domain/read-model/sql-read-model/schema'
    
    Log = CommonDomain::Logger.get "common-domain::read-model::sql-read-model"
    
    class InvalidStateError < ::StandardError
    end
    
    attr_reader :connection, :registry
    
    def initialize(connection, options = {})
      @options = {
      }.merge! options
      @connection = connection
      @registry   = DatasetsRegistry.new(connection)
      setup_registry(@registry)
      prepare_statements(@registry)
    end
    
    def setup
      if schema.meta_store_initialized? && schema.actual_schema_version != 0
        raise InvalidStateError.new "Looks like schema has already been initialized. Please rebuild your read model."
      end
      schema.setup
      prepare_statements(schema)
    end
    
    def cleanup!
      Log.warn "Read-model schema cleanup..."
      schema.cleanup
    end
    
    def rebuild_required?
      schema.rebuild_required?
    end
    
    def setup_required?
      schema.setup_required?
    end
    
    def schema
      nil
    end   
    
    protected
      def setup_registry(registry)
        #Runtime generated by self.setup_schema
      end
    
      def prepare_statements(registry)
        #Runtime generated by self.prepare_statements
      end
      
      def setup_schema(schema)
        #Runtime generated by self.setup_schema
      end
    
    class << self
      # &block to be called with schema
      def setup_schema(options = {}, &block)
        define_method(:schema) do
          options = { identifier: self.class.name, version: 0 }.merge! options
          @schema ||= Schema.new(@connection, options) do |schema|
            setup_schema(schema)
          end
        end
        define_method(:setup_schema, &block)
        define_method(:setup_registry, &block)
        private :setup_schema, :setup_registry
      end
      
      # &block to be called with DatasetsRegistry instance
      def prepare_statements(&block)
        define_method(:prepare_statements, block)
        protected :prepare_statements
      end
    end
  end
end
