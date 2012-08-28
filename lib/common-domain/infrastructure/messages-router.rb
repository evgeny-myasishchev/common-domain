module CommonDomain::Infrastructure
  
  # Routes messages to appropriate handlers
  module MessagesRouter
    Log = CommonDomain::Logger.get "common-domain::infrastructure::messages-router"
    
    class SeveralHandlersFound < ::StandardError
      def initialize(message)
        super("Several handlers found for message: #{message}")
      end
    end
    
    class NoHandlersFound < ::StandardError
      def initialize(message)
        super("No handlers found for message: #{message}")
      end
    end
    
    #Returns true if there is at least one handler registered
    def handlers?
      registered_handlers.length > 0
    end
    
    #Route the message
    def route(message, options = {})
      options = {
        :fail_if_no_handlers => false,
        :ensure_single_handler => false
      }.merge!(options)
      ensure_single_handler = options[:ensure_single_handler]
      Log.debug "Routing message: #{message.class}"
      
      handlers = registered_handlers.select { |handler| handler.can_handle_message?(message) }
      raise SeveralHandlersFound.new(message) if handlers.length > 1 && ensure_single_handler
      raise NoHandlersFound.new(message) if handlers.length == 0 && options[:fail_if_no_handlers]
      
      handler_result = nil
      handlers.each { |handler|
        Log.debug " - to handler: #{handler}"
        handler_result = handler.handle_message(message)
      }
      ensure_single_handler ? handler_result : nil
    end
    
    #Register messages handler
    def register(messages_handler)
      Log.debug "Registering handler: #{messages_handler.class}"
      registered_handlers << messages_handler
    end
    
    private
      def registered_handlers
        @registered_handlers ||= []
      end
  end
end
