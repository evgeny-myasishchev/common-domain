class CommonDomain::Projections::SqlProjection
  class Schema
    attr_reader :options, :datasets_registry
    MetaStoreTableName = :'read-model-schema-infos'
    def initialize(connection, options, &block)
      @options = {
        version: 1,
        identifier: nil
      }.merge! options
      raise ":identifier must be provided. Schema can not be initialized without an identifier." if @options[:identifier].nil?
      raise ":version must be no-zero value." if @options[:version] == 0
      
      @connection         = connection
      @table_names        = []
      @block              = block
      @tables_with_blocks = {} #key: name, value: setup blcok
      @datasets_registry  = DatasetsRegistry.new connection
      init_meta_store
      yield(self) if block_given?
    end
    
    def table_names
      @tables_with_blocks.keys
    end
    
    def actual_schema_version
      query = meta_store.filter(identifier: @options[:identifier]).to_a
      query.count == 1 ? query.first[:'schema-version'] : 0
    end
    
    def setup_required?
      actual_schema_version == 0
    end
    
    def rebuild_required?
      actual_schema_version != @options[:version]
    end
    
    def setup
      init_meta_store
      @tables_with_blocks.each_pair do |table_name, block|
        unless @connection.table_exists? table_name
          Log.debug "Creating table: #{table_name}"
          @connection.create_table(table_name, &block)
        end
      end
      query = meta_store.filter(identifier: @options[:identifier])
      if query.count == 1
        query.update(:'schema-version' => @options[:version])
      else
        meta_store.insert(:identifier => @options[:identifier], :'schema-version' => @options[:version])
      end
    end
    
    def cleanup
      table_names.each { |table_name| @connection.drop_table? table_name }
      meta_store.filter(:identifier => @options[:identifier]).delete
    end

    def table(key, name, &block)
      raise "Table name can not be nil for key: #{key}" if name.nil?
      @tables_with_blocks[name] = block
      @datasets_registry.table(key, name)
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
