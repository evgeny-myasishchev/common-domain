module Sample
  class Bootstrap < CommonDomain::Bootstrap
    include CommonDomain
    
    attr_reader :commands_dispatcher
    
    def initialize(&block)
      yield(self)
    end
    
    def with_event_store
      bootstrap_event_store do |with|
        with.log4r_logging
        with.in_memory_persistence
      end
    end
    
    def with_command_handlers
      @commands_dispatcher = CommandDispatcher.new do |dispatcher|
        dispatcher.register Sample::CommandHandlers::AccountHandlers.new(@repository)
      end
    end
    
    def with_read_models
      bootstrap_read_models do |read_models|
        read_models.register :accounts, Sample::ReadModels::AccountsReadModel.new
      end
    end
  end
end
