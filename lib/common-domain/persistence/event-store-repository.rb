module CommonDomain::Persistence
  class EventStoreRepository < Repository
    Log = CommonDomain::Logger.get("common-domain::persistence::event-store-repository")
    
    class EventStoreWork < AbstractWork
      attr_reader :repository
      def initialize(event_store, builder)
        @aggregates = {}
        @work = event_store.begin_work
        @repository = EventStoreRepository.new @work, builder
      end
      
      def get_by_id(aggregate_class, id)
        # We don't maintain identify map using aggregate_class + id because id is normally a guid which is unlikelly to duplicate
        return @aggregates[id] if @aggregates.key?(id)
        @aggregates[id] = @repository.get_by_id(aggregate_class, id)
      end
      
      def commit_changes(headers = {})
        @aggregates.values.each { |aggregate| @repository.save(aggregate) }
        @work.commit_changes headers
      end
    end
    
    def initialize(stream_opener, builder)
      @stream_opener = stream_opener
      @builder     = builder
    end
    
    def get_by_id(aggregate_class, aggregate_id)
      aggregate = @builder.build(aggregate_class, aggregate_id)
      stream    = @stream_opener.open_stream(aggregate_id)
      stream.committed_events.each { |event| aggregate.apply_event(event.body) }
      aggregate
    end
    
    def save(aggregate, headers = {})
      Log.debug "Saving aggregate: #{aggregate.aggregate_id}"
      stream = @stream_opener.open_stream(aggregate.aggregate_id)
      uncommitted_events = aggregate.get_uncommitted_events
      Log.debug "#{uncommitted_events.length} uncommitted events to commit..."
      uncommitted_events.each { |event|  
        stream.add EventStore::EventMessage.new event
      }
      stream.commit_changes headers
      aggregate.clear_uncommitted_events
      Log.debug "Done..."
      aggregate
    end
    
    protected
      def create_work
        EventStoreWork.new @stream_opener, @builder
      end
  end
end
