module CommonDomain::Infrastructure
  
  # Generic messages handler.
  # Sample usage:
  #
  # class YourMessagesHandler
  #    include CommonDomain::Infrastructure::MessagesHandler
  #    
  #    on MessageOne do |message|
  #      # message handling logic
  #    end
  #    
  #    on MessageOne do |message|
  #      # message handling logic
  #    end
  #
  #    #Optionally handle the message with headers.
  #    on MessageThree do |message, headers|
  #      # message handling logic
  #    end
  # end
  
  # handler = YourMessagesHandlers.new
  # handler.handle_message MessageOne.new #This will invoke appropriate handler
  #
  
  module MessagesHandler
    class HandlerAlreadyRegistered < ::StandardError
    end
    class UnknownHandlerError < ::StandardError
    end
    
    module Helpers
      protected
        def message_handler_name(message_class)
          "on-#{message_class.name}-message".to_sym
        end
    end
    
    module ClassMethods
      include Helpers
      protected
        def on message_class, &block
          handler_method = message_handler_name(message_class)
          if instance_methods.include?(handler_method)
            raise HandlerAlreadyRegistered.new("Handler for message '#{message_class}' already registered") 
          end
          define_method message_handler_name(message_class), &block
        end
    end
    
    module InstanceMethods
      include Helpers
      
      def can_handle_message?(message)
        respond_to?(message_handler_name(message.class))
      end
      
      def handle_message(message, headers = {})
        raise UnknownHandlerError.new "Handler for message '#{message.class}' not found in '#{self}'." unless can_handle_message?(message)
        _invoke_handler_method method(message_handler_name(message.class)), message, headers
      end
      
      protected
        def _invoke_handler_method(handler_method, message, headers = {})
          handler_method.arity == 1 ? handler_method.call(message) : handler_method.call(message, headers)
        end
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end
