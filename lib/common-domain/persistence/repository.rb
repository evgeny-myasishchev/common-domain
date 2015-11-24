module CommonDomain::Persistence
  class Repository
    include CommonDomain::Loggable
    
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