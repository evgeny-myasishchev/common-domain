module Sample::CommandHandlers
  class AccountHandlers < CommonDomain::CommandHandler
    require 'securerandom'
    include Sample::Commands::AccountCommands
    include Sample::Domain
     
    on OpenAccountCommand do |command|
     account = Account.open_account SecureRandom.uuid, command.account_name
     repository.save account
    end

    on RenameAccountCommand do |command|
     account = repository.get_by_id Account, command.aggregate_id
     account.rename_account command.new_name
     repository.save account
    end
    
    on CloseAccountCommand do |command|
     account = repository.get_by_id Account, command.aggregate_id
     account.close_account command.reason
     repository.save account
    end
  end
end