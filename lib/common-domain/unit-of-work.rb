module CommonDomain
  class UnitOfWork
    attr_reader :repository
    def initialize(repository)
      ensure_transactions_supported! repository
      @repository = repository
      @tracked_aggregates = {}      
    end
    
    def get_by_id aggregate_class, aggregate_id
      @tracked_aggregates[aggregate_id] ||= @repository.get_by_id aggregate_class, aggregate_id
    end
    
    def add_new aggregate
      @tracked_aggregates[aggregate.aggregate_id] = aggregate
    end
    
    def commit(headers)
      @repository.event_store.transaction do
        @tracked_aggregates.values.each do |aggregate|
          @repository.save aggregate, headers
        end
      end
    end
    
    private def ensure_transactions_supported! repository
      raise 'Can not use UnitOfWork. Underlying persistence engine does not support transactions.' unless repository.event_store.persistence_engine.supports_transactions?
    end
  end
end