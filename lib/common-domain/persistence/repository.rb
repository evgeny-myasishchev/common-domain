module CommonDomain::Persistence
  class Repository
    include CommonDomain::Loggable
    include CommonDomain::Persistence::Hookable

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
    
    # Returns the aggregate. Raises AggregateNotFoundError for not existing aggregates.
    # If block supplied then the aggregate will be automatically saved after the block exists
    def get_by_id(aggregate_class, aggregate_id)
      snapshot = get_snapshot(aggregate_id)
      logger.debug "Loading the aggregate #{aggregate_class} id='#{aggregate_id}'." if snapshot.nil?
      logger.debug "Loading the aggregate #{aggregate_class} id='#{aggregate_id}' from the snapshot (version=#{snapshot.version})." unless snapshot.nil?
      stream = get_stream aggregate_class, aggregate_id, snapshot
      aggregate = @builder.build(aggregate_class, snapshot || aggregate_id)
      stream.committed_events.each { |event| aggregate.apply_event(event) }
      aggregate
    end
    
    def save(aggregate, headers = {})
      uncommitted_events = aggregate.get_uncommitted_events
      if uncommitted_events.length > 0
        logger.debug "Saving the aggregate #{aggregate.class} id='#{aggregate.aggregate_id}' with '#{uncommitted_events.length}' uncommitted events..."
        # If there is no open stream then this means we're creating new aggregate
        stream = @streams[aggregate.aggregate_id] || @event_store.create_stream(aggregate.aggregate_id)
        uncommitted_events.each { |event| stream.add event }
        logger.debug 'Committing changes...'
        stream.commit_changes headers
        aggregate.clear_uncommitted_events
        logger.debug "Aggregate #{aggregate.class} id='#{aggregate.aggregate_id}' saved."
        add_snapshot_if_required aggregate, stream
      else
        logger.debug "The aggregate #{aggregate.class} id='#{aggregate.aggregate_id}' has no uncommitted events. Saving skipped."
      end
      call_hooks :after_commit
      aggregate
    end

    private
    
    def get_snapshot aggregate_id
      return @snapshots[aggregate_id] if @snapshots.key?(aggregate_id)
      snapshot = @snapshots_repository.nil? ? nil : @snapshots_repository.get(aggregate_id)
      @snapshots[aggregate_id] = snapshot
      snapshot
    end
    
    def get_stream aggregate_class, stream_id, snapshot
      return @streams[stream_id] if @streams.key?(stream_id)
      raise CommonDomain::Persistence::AggregateNotFoundError.new(aggregate_class, stream_id) unless @event_store.stream_exists?(stream_id)
      stream = snapshot.nil? ? @event_store.open_stream(stream_id) : @event_store.open_stream(stream_id, min_revision: snapshot.version + 1)
      @streams[stream_id] = stream
      stream
    end
    
    def add_snapshot_if_required(aggregate, stream)
      return if @snapshots_repository.nil?
      return unless aggregate.class.add_snapshot?(aggregate)
      logger.debug "Adding snapshot for aggregate #{aggregate.class} id=#{stream.stream_id} (version: #{stream.stream_revision})"
      snapshot = CommonDomain::Persistence::Snapshots::Snapshot.new stream.stream_id, stream.stream_revision, aggregate.get_snapshot
      @snapshots_repository.add snapshot
    end
  end
end