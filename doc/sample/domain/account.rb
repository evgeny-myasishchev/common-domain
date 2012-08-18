module Sample::Domain
  class Account < CommonDomain::Aggregate
    include Sample::Events::AccountEvents
    
    def initialize(aggregate_id)
      super(aggregate_id)
      @name      = nil
      @is_active = true
    end
    
    def self.open_account(account_number, account_name)
      raise "Account number can not be empty" if account_number == nil
      raise "Account name can not be empty" if account_name == nil || account_name.empty?
      account = new account_number
      account.send :raise_event, AccountOpenedEvent.new(account_number, account_name)
      account
    end
    
    def rename_account(new_name)
      raise "New name can not be empty" if new_name == nil || new_name.empty?
      raise_event AccountRenamedEvent.new aggregate_id, new_name
    end
    
    def close_account(reason)
      raise "Account already closed" unless @is_active
      raise_event AccountClosedEvent.new aggregate_id, reason
    end
    
    on AccountOpenedEvent do |event|
      @id   = event.aggregate_id
      @name = event.account_name
    end
    
    on AccountRenamedEvent do |event|
      @name = event.new_name
    end
    
    on AccountClosedEvent do |event|
      @is_active = false
    end
  end
end
