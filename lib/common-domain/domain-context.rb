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
    
    def initialize_read_models(options = {})
      options = {
        :cleanup_all => false
      }.merge! options
      bus         = EventBus.new
      cleanup_all = options[:cleanup_all]
      Log.info "Initializing read models. Cleanup all option is: #{cleanup_all}"
      
      read_models.for_each do |read_model|
        Log.info "Checking read model: #{read_model}"
        if cleanup_all || read_model.rebuild_required?
          Log.info "Read model needs rebuild."
          Log.info "Cleaning read model..."
          read_model.cleanup!
          Log.info "Setup clean read model..."
          read_model.setup
          bus.register read_model
        elsif read_model.setup_required?
          Log.info "Doing setup of new read model: #{read_model}"
          read_model.setup
          bus.register read_model
        end
      end
      
      if bus.handlers?
        Log.info "Publishing all events..."
        event_store.persistence_engine.for_each_commit do |commit|
          commit.events.each { |event| 
            bus.publish(event.body) 
          }
        end
        Log.info "Read models initialized."
      else
        Log.info "Looks like no read models needs to be initialized this time."
      end
    end
    
    # Rebuilds required read models.
    def with_read_models_initialization
      initialize_read_models :cleanup_all => false
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
