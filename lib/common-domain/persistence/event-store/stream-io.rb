module CommonDomain::Persistence::EventStore
  module StreamIO
    Log = CommonDomain::Logger.get("common-domain::persistence::event-store::stream-io")
    
    def flush_changes aggregate, stream_opener, &block
      Log.debug "Saving aggregate: #{aggregate.aggregate_id}"
      stream = stream_opener.open_stream(aggregate.aggregate_id)
      uncommitted_events = aggregate.get_uncommitted_events
      Log.debug "#{uncommitted_events.length} uncommitted events to commit..."
      uncommitted_events.each { |event|  
        stream.add EventStore::EventMessage.new event
      }
      yield(stream) if block_given?
      aggregate.clear_uncommitted_events
      Log.debug "Done..."
      aggregate
    end
  end
end