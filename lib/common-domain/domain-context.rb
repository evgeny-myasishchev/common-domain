require 'sequel'

module CommonDomain
  class DomainContext
    Log = Logger.get "common-domain::domain-context"
    
    attr_reader :event_store
    attr_reader :repository
    attr_reader :application_event_bus
    attr_reader :domain_events_bus
    attr_reader :read_models
    attr_reader :command_dispatcher
    attr_reader :event_store_database_config
    attr_reader :read_store_database_config
    
    def initialize(&block)
      @application_event_bus = EventBus.new
      yield(self) if block_given?
    end
    
    #
    # database_configuration expected to have "event-store" and "read-store" connection specifications.
    # For SQL databases connection specification should be Sequel friendly
    # See here for details: http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html
    # 
    # If 'event-store' or 'read-store' specifications not found then fallback_config_name attempted
    #
    def with_database_configs(database_configuration, fallback_config_name = 'default')
      default_db_config = nil
      if database_configuration.key?(fallback_config_name)
        default_db_config            = database_configuration[fallback_config_name].dup
        default_db_config["adapter"] = "sqlite" if default_db_config["adapter"] == "sqlite3"
      end
      @event_store_database_config = database_configuration.key?("event-store") ? database_configuration['event-store'] : default_db_config
      @read_store_database_config  = database_configuration.key?("read-store") ? database_configuration["read-store"] : default_db_config
    end
    
    def with_event_store
      # bootstrap_event_store do |with|
      #   with.log4r_logging
      # end
      raise "Override me and do extra setup of the event store. At least logging should be initialized."
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
        @domain_events_bus = CommonDomain::EventBus.new
        @read_models       = CommonDomain::ReadModel::Registry.new @domain_events_bus
        yield(@read_models)
      end
    
      def bootstrap_event_store(&block)
        Log.info "Initializing event store..."
        Log.debug "Using connection specification: #{event_store_database_config}"

        raise "Event Bus should be initialized" if domain_events_bus.nil?
        @event_store = EventStore.bootstrap do |with|
          # with.log4r_logging
          yield(with)
          #At this point SQL persistence only is supported.
          with.sql_persistence event_store_database_config
          with.synchorous_dispatcher do |commit|
            commit.events.each { |event| 
              domain_events_bus.publish(event.body) 
            }
          end
        end
        aggregates_builder = Persistence::AggregatesBuilder.new
        @repository        = Persistence::EventStore::Repository.new(@event_store, aggregates_builder)
      end
      
      def bootstrap_command_handlers(&block)
        @command_dispatcher = CommandDispatcher.new(&block)
      end
  end
end
