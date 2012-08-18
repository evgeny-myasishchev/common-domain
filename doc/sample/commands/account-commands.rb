module Sample::Commands
  module AccountCommands
    class OpenAccountCommand < CommonDomain::Command
      attr_reader :account_name
      def initialize(account_name)
        super(nil, :account_name => account_name)
      end
    end
    
    class RenameAccountCommand < CommonDomain::Command
      attr_reader :new_name
      def initialize(account_number, new_name)
        super(account_number, :new_name => new_name)
      end
    end
    
    class CloseAccountCommand < CommonDomain::Command
      attr_reader :reason
      def initialize(account_number, reason)
        super(account_number, :reason => reason)
      end
    end
  end
end