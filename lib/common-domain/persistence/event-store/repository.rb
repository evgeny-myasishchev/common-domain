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
      flush_changes aggregate, @event_store do |stream|
        Log.debug "Committing changes..."
        stream.commit_changes headers
      end
      Log.debug "Aggregate '#{aggregate.aggregate_id}' saved."
      aggregate
    end
    
    protected
      def create_work
        Work.new @event_store, @builder
      end
  end
end
