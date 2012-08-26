class CommonDomain::ReadModel::SqlReadModel
  class Schema
    attr_reader :table_names, :options
    MetaStoreTableName = :'read-model-schema-infos'
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
    
    def rebuild_required?
      return true unless @connection.table_exists?(MetaStoreTableName)
      query = @connection[MetaStoreTableName].filter(identifier: @options[:identifier])
      return true unless query.count == 1
      return true unless @options[:version] == query.first[:'schema-version']
      return false
    end
    
    def setup
      meta_store = init_meta_store
      @block.call(self)
      query = meta_store.filter(identifier: @options[:identifier])
      if query.count == 1
        query.update(:'schema-version' => @options[:version])
      else
        meta_store.insert(:identifier => @options[:identifier], :'schema-version' => @options[:version])
      end
    end
    
    def cleanup
      
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
    
    private
      def init_meta_store
        @connection.create_table?(MetaStoreTableName) do
          String :identifier, :size => 200, :primary_key => true, :allow_null => false
          Integer :'schema-version', :allow_null => false
        end
        @connection[MetaStoreTableName]
      end
  end
end
