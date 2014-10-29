module CommonDomain::Persistence
  class Repository
    Log = CommonDomain::Logger.get("common-domain::persistence::repository")
    
    def exists?(aggregate_id)
      raise 'Not implemented'
    end
    
    # Returns the aggregate. Raises AggregateNotFoundError for not existing aggregates.
    # If block supplied then the aggregate will be automatically saved after the block exists
    def get_by_id(aggregate_class, id)
      raise "Not implemented"
    end
    
    def save(aggregate, headers = {})
      raise "Not implemented"
    end
  end
end