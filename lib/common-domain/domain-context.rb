require 'sequel'

module CommonDomain
  class DomainContext
    Log = Logger.get "common-domain::domain-context"
    
    attr_reader :event_store
    attr_reader :repository
    attr_reader :event_bus
    attr_reader :read_models
    
    def initialize(&block)
      yield(self) if block_given?
    end
    
    def rebuild_read_models(options = {})
      options = {
        :required_only => false
      }.merge! options
      bus                   = EventBus.new
      should_publish_events = false
      Log.info "Going to rebuild read models. Required only: #{options[:required_only]}..."
      read_models.for_each do |rm|
        rebuild_this_one = !options[:required_only] || rm.rebuild_required?
        if rebuild_this_one
          Log.warn "Purging read model: #{rm}"
          rm.purge!
        
          #Registering it in the bus for further dispatching
          bus.register rm
          should_publish_events = true
        end
      end
      
      if should_publish_events
        Log.info "Publishing all events..."
        event_store.persistence_engine.for_each_commit do |commit|
          commit.events.each { |event| 
            bus.publish(event.body) 
          }
        end
        Log.info "Read models rebuilt."
      else
        Log.info "Rebuild not required this time."
      end
    end
    
    # Rebuilds required read models.
    def with_rebuild_required_read_models
      rebuild_read_models :required_only => true
    end
    
    def with_dispatch_undispatched_commits
      event_store.dispatch_undispatched
    end

    protected
      def bootstrap_read_models(&block)
        @event_bus   = CommonDomain::EventBus.new
        @read_models = CommonDomain::ReadModel::Registry.new @event_bus
        yield(@read_models)
      end
    
      def bootstrap_event_store(&block)
        raise "Event Bus should be initialized" if event_bus.nil?
        @event_store = EventStore.bootstrap do |with|
          # with.log4r_logging
          # with.sql_persistence connection_specification
          yield(with)
          with.synchorous_dispatcher do |commit|
            commit.events.each { |event| 
              event_bus.publish(event.body) 
            }
          end
        end
        aggregates_builder = Persistence::AggregatesBuilder.new
        @repository        = Persistence::EventStoreRepository.new(@event_store, aggregates_builder)
      end
  end
end
