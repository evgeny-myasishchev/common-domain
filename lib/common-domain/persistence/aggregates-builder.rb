module CommonDomain::Persistence
  class AggregatesBuilder
    def build(aggregate_class, id, snapshot: nil)
      aggregate = aggregate_class.new id
      aggregate.apply_snapshot(snapshot) if(snapshot)
      aggregate
    end
  end
end