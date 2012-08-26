module CommonDomain::ReadModel
  class SqlReadModel < Base
    autoload :Schema, 'common-domain/read-model/sql-read-model/schema'
    
    Log = CommonDomain::Logger.get "common-domain::read-model::sql-read-model"
    
    class InvalidStateError < ::StandardError
    end
    
    attr_reader :connection
    
    def initialize(connection, options = {})
      @options = {
      }.merge! options
      @connection = connection
    end
    
    def setup
      schema.setup
      prepare_statements(schema)
    end
    
    def purge!
      Log.warn "Purging all data..."
      schema.cleanup
      schema.setup
    end
    
    def rebuild_required?
      schema.rebuild_required?
    end
    
    def schema
      nil
    end   
    
    protected
      def prepare_statements(schema)
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
        private :setup_schema
      end
      
      # &block to be called with schema
      def prepare_statements(&block)
        define_method(:prepare_statements, block)
        protected :prepare_statements
      end
    end
  end
end
