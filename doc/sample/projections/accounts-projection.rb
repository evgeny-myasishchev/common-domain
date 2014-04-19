module Sample::Projections
  class AccountsProjection
    include Sample::Events::AccountEvents
    include CommonDomain::Infrastructure::MessagesHandler
    
    def initialize
      @accounts = {}
    end
    
    def get_accounts_list
      @accounts.values.dup
    end
    
    on AccountOpenedEvent do |event|
      @accounts[event.aggregate_id] = {
        :number => event.aggregate_id,
        :name => event.account_name,
        :is_active => true
      }
    end
    
    on AccountRenamedEvent do |event|
      @accounts[event.aggregate_id][:name] = event.new_name
    end
    
    on AccountClosedEvent do |event|
      @accounts[event.aggregate_id][:is_active] = false
    end
  end
end