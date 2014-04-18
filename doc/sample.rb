$:.unshift File.expand_path("..", __FILE__)

require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup'
require 'event-store'
require 'common-domain'

#Configure logging
require 'log4r'
require 'log4r/yamlconfigurator'
require 'log4r/outputter/rollingfileoutputter'

FileUtils.mkdir 'log' unless Dir.exists? 'log'

log4r_config = YAML.load_file(File.expand_path('../config/log4r.yml', __FILE__))
Log4r::YamlConfigurator.decode_yaml(log4r_config['log4r_config'])

Log = Log4r::Logger["common-domain::sample"]

module Sample
  require 'sample/events/account-events'
  require 'sample/domain/account'
  require 'sample/commands/account-commands'
  require 'sample/command-handlers/account-handlers'
  require 'sample/read-models/accounts-read-model'
  require 'sample/infrastructure/context'
end

app = Sample::Context.new do |bootstrap|
  bootstrap.with_read_models
  bootstrap.with_event_store
  bootstrap.with_command_handlers
end

Log.info "== Createing some accounts =="
app.command_dispatcher.dispatch Sample::Commands::AccountCommands::OpenAccountCommand.new "Primary Account"
app.command_dispatcher.dispatch Sample::Commands::AccountCommands::OpenAccountCommand.new "Business Account"

Log.info "== Showing created accounts =="
Log.info "number;name;is active?"
accounts_list = app.read_models.accounts.get_accounts_list
accounts_list.each { |account| 
  Log.info "#{account[:number]};#{account[:name]};#{account[:is_active]}"
}
Log.info "=="

Log.info "== Renaming first account =="
account_to_rename = accounts_list[0]
app.command_dispatcher.dispatch Sample::Commands::AccountCommands::RenameAccountCommand.new account_to_rename[:number], "Primary Family Account"

Log.info "== Deactivating second account =="
account_to_close = accounts_list[1]
app.command_dispatcher.dispatch Sample::Commands::AccountCommands::CloseAccountCommand.new account_to_close[:number], "Reorganized business."

Log.info "== Showing changed accounts =="
Log.info "number;name;is active?"
accounts_list = app.read_models.accounts.get_accounts_list
accounts_list.each { |account| 
  Log.info "#{account[:number]};#{account[:name]};#{account[:is_active]}"
}
Log.info "=="