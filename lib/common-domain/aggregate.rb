module CommonDomain
  
  require_relative 'logger'
  require_relative 'messages/messages-handler'
  
  # 
  # Base class for all domain models.
  # 
  class Aggregate
    Log = CommonDomain::Logger.get("common-domain::aggregate")
    include Messages::MessagesHandler
    
    attr_reader :aggregate_id, :version
    
    # Number of applied events. If there was a snapshot then 
    # this would be a number of events applied since the snapshot
    # Main use of this is to detect if the aggregate needs a snapshot.
    # See the add_snapshot? method for more details.
    attr_reader :applied_events_number
    
    def initialize(id_or_snapshot = nil)
      if id_or_snapshot.is_a?(CommonDomain::Persistence::Snapshots::Snapshot)
        snapshot = id_or_snapshot
        @aggregate_id = snapshot.id
        @version = snapshot.version
        apply_snapshot snapshot.data
      else
        @aggregate_id = id_or_snapshot
        @version = 0
      end
      @uncommitted_events = []
      @applied_events_number = 0
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
    # Simplified on syntax can be used as well. Sample:
    # on AccountClosedEvent do |event| {
    #   #Your logic goes here
    # }
    #
    def apply_event(event)
      handle_message(event)
      @version += 1
      @applied_events_number += 1
      self
    end
    
    # Reconstruct the state of the aggregate as a snapshot
    def apply_snapshot(data)
      raise 'Not implemented'
    end
    
    # Get current state (snapshot). Data returned by this method should be recognized by apply_snapshot method
    def get_snapshot
      raise 'Not implemented'
    end
    
    def get_uncommitted_events
      @uncommitted_events.clone
    end
    
    def clear_uncommitted_events
      @uncommitted_events.clear
    end
    
    #
    # Should be overridden by specific aggregate class and return true if condition to add snapshot is meat
    # In general you would add a snapshot if it has applied events number greather than some threashold. 
    # Example of such logic would look like:
    # aggregate.applied_events_number >= 10
    #
    def self.add_snapshot?(aggregate)
      false
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
        @uncommitted_events << event
        self
      end
  end
end