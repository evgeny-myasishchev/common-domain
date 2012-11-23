module CommonDomain::Persistence::EventStore
  class Repository < CommonDomain::Persistence::Repository
    include CommonDomain::Persistence::EventStore::StreamIO
    
    Log = CommonDomain::Logger.get("common-domain::persistence::event-store::repository")
    
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
      flush_changes aggregate, @stream_opener do |stream|
        stream.commit_changes headers
      end
    end
    
    protected
      def create_work
        Work.new @stream_opener, @builder
      end
  end
end
