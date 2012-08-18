module CommonDomain::Persistence
  class AggregatesBuilder
    def build(aggregate_class, id)
      aggregate_class.new id
    end
  end
end