class CommonDomain::ReadModel::SqlReadModel
  class DatasetsRegistry
    attr_reader :connection
    def initialize(connection)
      @connection = connection
      @datasets   = {}
    end
    
    def table(access_key, table_name)
      @datasets[access_key] = @connection[table_name]
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
