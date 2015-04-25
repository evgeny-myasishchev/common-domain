module CommonDomain
  
  # Used to register command handlers and dispatch commands to handlers.
  # Sample:
  #
  # dispatcher = CommandDispatcher.new do |dispatcher|
  #   dispatcher.register Sample::CommandHandlers::AccountHandlers.new
  # end  
  #
  # dispatcher.dispatch AccountCreatedCommand.new
  #
  class CommandDispatcher
    include Messages::MessagesRouter
    def initialize(&block)
      yield self if block_given?
    end
    
    def dispatch(command)
      options = {ensure_single_handler: true, fail_if_no_handlers: true}
      route(command, options)
    end
  end
end