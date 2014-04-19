module Sample
  class Context < CommonDomain::DomainContext
    include CommonDomain
    
    attr_reader :command_dispatcher
    
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
      @command_dispatcher = CommandDispatcher.new do |dispatcher|
        dispatcher.register Sample::CommandHandlers::AccountHandlers.new(@repository)
      end
    end
    
    def with_projections
      bootstrap_projections do |projections|
        projections.register :accounts, Sample::Projections::AccountsProjection.new
      end
    end
  end
end
