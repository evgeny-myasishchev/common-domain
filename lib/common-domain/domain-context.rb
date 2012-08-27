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
        :required_only => true
      }
    end

    protected
      def bootstrap_read_models(&block)
        @event_bus   = CommonDomain::EventBus.new
        @read_models = CommonDomain::ReadModel::Registry.new @event_bus
        yield(@read_models)
        
        Log.info "Initializing read models..."
        @read_models.for_each do |read_model|
          Log.info "- setup: #{read_model}"
          read_model.setup
        end
      end
    
      def bootstrap_event_store(&block)
        raise "Event Bus should be initialized" if event_bus.nil?
        @event_store = EventStore::Bootstrap.store do |with|
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
