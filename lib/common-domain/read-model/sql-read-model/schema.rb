class CommonDomain::ReadModel::SqlReadModel
  class Schema
    attr_reader :table_names, :options
    MetaStoreTableName = :'read-model-schema-infos'
    def initialize(connection, options, &block)
      @options = {
        version: 1,
        identifier: nil
      }.merge! options
      raise ":identifier must be provided. Schema can not be initialized without an identifier." if @options[:identifier].nil?
      
      @connection  = connection
      @table_names = []
      @block       = block
    end
    
    def meta_store_initialized?
      @connection.table_exists?(MetaStoreTableName)
    end
    
    def actual_schema_version
      raise "Schema meta store has not been initialized yet. Can not obtain actual schema version." unless meta_store_initialized?
      query = meta_store.filter(identifier: @options[:identifier])
      query.count == 1 ? query.first[:'schema-version'] : 0
    end
    
    def setup_required?
      return true unless meta_store_initialized?
      actual_schema_version == 0
    end
    
    def rebuild_required?
      return true unless meta_store_initialized?
      actual_schema_version != @options[:version]
    end
    
    def setup
      init_meta_store
      @block.call(self)
      query = meta_store.filter(identifier: @options[:identifier])
      if query.count == 1
        query.update(:'schema-version' => @options[:version])
      else
        meta_store.insert(:identifier => @options[:identifier], :'schema-version' => @options[:version])
      end
    end
    
    def cleanup
      table_names.each { |table_name| @connection.drop_table table_name }
      meta_store.filter(:identifier => @options[:identifier]).delete
    end

    def table(key, name, &block)
      raise "Table name can not be nil for key: #{key}" if name.nil?
      unless @connection.table_exists? name
        Log.debug "Creating table: #{name}"
        @connection.create_table(name, &block)
      end
      @table_names << name
      nil
    end
    
    private
      def meta_store
        @meta_store ||= @connection[MetaStoreTableName]
      end
    
      def init_meta_store
        @connection.create_table?(MetaStoreTableName) do
          String :identifier, :size => 200, :primary_key => true, :allow_null => false
          Integer :'schema-version', :allow_null => false
        end
      end
  end
end
