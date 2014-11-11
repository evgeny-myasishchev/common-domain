module CommonDomain::Persistence
  class AggregatesBuilder
    def build(aggregate_class, id, snapshot: nil)
      snapshot.nil? ? aggregate_class.new(id) : aggregate_class.new(snapshot)
    end
  end
end