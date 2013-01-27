module CommonDomain
  
  # 
  # Base class for all domain models.
  # 
  class Aggregate
    include Infrastructure::MessagesHandler
    
    attr_reader :aggregate_id, :version
    
    def initialize(id = nil)
      @aggregate_id = id
      @version = 0
      @uncommitted_events = []
    end
    
    # Dispatch the event to a corresponding handler.
    # The handler is a method in form of 'on_xxx' which is resolved at runtime
    # from class name of the event. Where xxx is underscored event class name.
    #
    # Samples:
    # * class Events::AccountOpenedEvent resolved to on_account_opened
    # * class AccountClosedEvent resolved to on_account_closed
    # 
    # The handler should accept a single argument, the event itself.
    #
    def apply_event(event)
      handle_message(event)
      @version = event.version
      self
    end
    
    def get_uncommitted_events
      @uncommitted_events.clone
    end
    
    def clear_uncommitted_events
      @uncommitted_events.clear
    end
    
    protected
    
      # This method should be used by subclasses to publish events which are results of aggregate state change.
      # Sample:
      #
      # class Account
      #   def close_account
      #     #Do domain logic
      #     raise_event AccountClosed.new id
      #   end
      # end
      #
      def raise_event(event)
        apply_event(event)
        event.version = version + 1
        @uncommitted_events << event
        self
      end
      
      # Instantiates the entity of specified class and returns it
      def new_entity(entity_class)
        entity_class.new(self)
      end
  end
end