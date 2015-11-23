module CommonDomain::Bootstrap
  class EventStoreWireup
    Log = CommonDomain::Logger.get "common-domain::bootstrap::event-store-wireup"
    
    def initialize(dispatcher: :asynchronous)
      
    end
    
    def call(deps)
      Log.info "Initializing event store..."

      # ensure_event_bus!
      # deps[:event_store] = EventStore.bootstrap do |with|
      #   # with.log4r_logging
      #   yield(with)
      #   unless with.has_persistence_engine?
      #     raise 'Please setup event-store persistence' #TODO: Maybe use dedicated exception calss
      #   end
      #   with.send("#{dispatcher}_dispatcher") do |commit|
      #     commit_context = CommonDomain::CommitContext.new commit
      #     commit.events.each { |event|
      #       event_bus.publish(event.body, context: commit_context)
      #     }
      #   end
      # end
    end
    
    def self.create(dispatcher: :asynchronous, &block)
      EventStoreWireup.new(dispatcher: dispatcher)
    end
  end
end