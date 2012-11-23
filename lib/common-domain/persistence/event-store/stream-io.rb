module CommonDomain::Persistence::EventStore
  module StreamIO
    Log = CommonDomain::Logger.get("common-domain::persistence::event-store::stream-io")
    
    def flush_changes aggregate, stream_opener, &block
      Log.debug "Flushing uncommitted events of aggregate '#{aggregate.aggregate_id}' into it's stream..."
      stream = stream_opener.open_stream(aggregate.aggregate_id)
      uncommitted_events = aggregate.get_uncommitted_events
      Log.debug "#{uncommitted_events.length} uncommitted events to flush..."
      uncommitted_events.each { |event|  
        stream.add EventStore::EventMessage.new event
      }
      yield(stream) if block_given?
      aggregate.clear_uncommitted_events
      Log.debug "Aggregate flushed."
      aggregate
    end
  end
end