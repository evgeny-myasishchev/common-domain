module CommonDomain::Persistence::EventStore
  class Repository < CommonDomain::Persistence::Repository
    Log = CommonDomain::Logger.get("common-domain::persistence::event-store::repository")
    
    def initialize(event_store, builder, snapshots_repository = nil)
      @event_store = event_store
      @builder = builder
      @snapshots_repository = snapshots_repository
    end
    
    def exists?(aggregate_id)
      @event_store.stream_exists?(aggregate_id)
    end
    
    def get_by_id(aggregate_class, aggregate_id)
      snapshot = @snapshots_repository.nil? ? nil : @snapshots_repository.get(aggregate_id)
      Log.debug "Loading the aggregate '#{aggregate_id}' from the snapshot (version=#{snapshot.version})." unless snapshot.nil?
      stream = snapshot.nil? ? @event_store.open_stream(aggregate_id) : @event_store.open_stream(aggregate_id, min_revision: snapshot.version + 1)
      raise CommonDomain::Persistence::AggregateNotFoundError.new(aggregate_class, aggregate_id) if stream.new_stream?
      aggregate = @builder.build(aggregate_class, snapshot || aggregate_id)
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
