module CommonDomain::Persistence::EventStore
  class Repository < CommonDomain::Persistence::Repository
    include CommonDomain::Persistence::EventStore::StreamIO
    
    Log = CommonDomain::Logger.get("common-domain::persistence::event-store::repository")
    
    def initialize(event_store, builder)
      @event_store = event_store
      @builder = builder
    end
    
    def exists?(aggregate_id)
      @event_store.stream_exists?(aggregate_id)
    end
    
    def get_by_id(aggregate_class, aggregate_id)
      stream = @event_store.open_stream(aggregate_id)
      raise CommonDomain::Persistence::AggregateNotFoundError.new(aggregate_class, aggregate_id) if stream.new_stream?
      aggregate = @builder.build(aggregate_class, aggregate_id)
      stream.committed_events.each { |event| aggregate.apply_event(event.body) }
      aggregate
    end
    
    def save(aggregate, headers = {})
      Log.debug "Saving aggregate '#{aggregate.aggregate_id}'..."
      stream = @event_store.open_stream(aggregate.aggregate_id)
      uncommitted_events = aggregate.get_uncommitted_events
      Log.debug "The aggregate '#{aggregate.aggregate_id}' has #{uncommitted_events.length} uncommitted events to flush..."
      uncommitted_events.each { |event|
        stream.add EventStore::EventMessage.new event
      }
      Log.debug "Committing changes..."
      stream.commit_changes headers
      aggregate.clear_uncommitted_events
      Log.debug "Aggregate '#{aggregate.aggregate_id}' saved."
      aggregate
    end
  end
end
