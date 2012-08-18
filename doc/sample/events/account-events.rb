module Sample::Events
  module AccountEvents
    class AccountOpenedEvent < CommonDomain::DomainEvent
      attr_reader :account_name
      def initialize(aggregate_id, account_name)
        super(aggregate_id, {:account_name => account_name})
      end
    end
  
    class AccountRenamedEvent < CommonDomain::DomainEvent
      attr_reader :new_name
      def initialize(aggregate_id, new_name)
        super(aggregate_id, {:new_name => new_name})
      end
    end
  
    class AccountClosedEvent < CommonDomain::DomainEvent
      attr_reader :reason
      def initialize(aggregate_id, reason)
        super(aggregate_id, {:reason => reason})
      end
    end
  end
end