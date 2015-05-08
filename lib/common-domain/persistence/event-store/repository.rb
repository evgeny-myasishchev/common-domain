module CommonDomain::Persistence::EventStore
  class Repository < CommonDomain::Persistence::Repository
    Log = CommonDomain::Logger.get("common-domain::persistence::event-store::repository")
    attr_reader :event_store
    def initialize(event_store, builder, snapshots_repository = nil)
      @event_store = event_store
      @builder = builder
      @snapshots_repository = snapshots_repository
      @streams = {}
      @snapshots = {}
    end
    
    def exists?(aggregate_id)
      @event_store.stream_exists?(aggregate_id)
    end
    
    def get_by_id(aggregate_class, aggregate_id)
      snapshot = get_snapshot(aggregate_id)
      Log.debug "Loading the aggregate '#{aggregate_id}' from the snapshot (version=#{snapshot.version})." unless snapshot.nil?
      stream = get_stream aggregate_id, snapshot
      raise CommonDomain::Persistence::AggregateNotFoundError.new(aggregate_class, aggregate_id) if stream.new_stream?
      aggregate = @builder.build(aggregate_class, snapshot || aggregate_id)
      stream.committed_events.each { |event| aggregate.apply_event(event.body) }
      aggregate
    end
    
    def save(aggregate, headers = {}, transaction = nil)
      uncommitted_events = aggregate.get_uncommitted_events
      if uncommitted_events.length > 0
        Log.debug "Saving the aggregate '#{aggregate.aggregate_id}' with '#{uncommitted_events.length}' uncommitted events..."
        stream = @streams[aggregate.aggregate_id] || @event_store.open_stream(aggregate.aggregate_id)
        uncommitted_events.each { |event|
          stream.add EventStore::EventMessage.new event
        }
        Log.debug "Committing changes..."
        if transaction
          stream.commit_changes transaction, headers
        else
          @event_store.transaction { |t| stream.commit_changes t, headers }
        end
        aggregate.clear_uncommitted_events
        Log.debug "Aggregate '#{aggregate.aggregate_id}' saved."
        add_snapshot_if_required aggregate, stream
      else
        Log.debug "The aggregate '#{aggregate.aggregate_id}' has no uncommitted events. Saving skipped."
      end
      aggregate
    end
    
    private
      def get_snapshot aggregate_id
        return @snapshots[aggregate_id] if @snapshots.key?(aggregate_id)
        snapshot = @snapshots_repository.nil? ? nil : @snapshots_repository.get(aggregate_id)
        @snapshots[aggregate_id] = snapshot
        snapshot
      end
    
      def get_stream stream_id, snapshot
        return @streams[stream_id] if @streams.key?(stream_id)
        stream = snapshot.nil? ? @event_store.open_stream(stream_id) : @event_store.open_stream(stream_id, min_revision: snapshot.version + 1)
        @streams[stream_id] = stream
        stream
      end
    
      def add_snapshot_if_required(aggregate, stream)
        return if @snapshots_repository.nil?
        return unless aggregate.class.add_snapshot?(aggregate)
        Log.debug "Adding snapshot for aggregate #{stream.stream_id} (version: #{stream.stream_revision})"
        snapshot = CommonDomain::Persistence::Snapshots::Snapshot.new stream.stream_id, stream.stream_revision, aggregate.get_snapshot
        @snapshots_repository.add snapshot
      end
  end
end
