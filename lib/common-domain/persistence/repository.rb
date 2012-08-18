module CommonDomain::Persistence
  class Repository
    def get_by_id(aggregate_class, id)
      raise "Not implemented"
    end
    
    def save(aggregate)
      raise "Not implemented"
    end
  end
end