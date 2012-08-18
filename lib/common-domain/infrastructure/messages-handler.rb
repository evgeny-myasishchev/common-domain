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
  # end
  
  # handler = YourMessagesHandlers.new
  # handler.handle_message MessageOne.new #This will invoke appropriate handler
  #
  
  module MessagesHandler
    class HandlerAlreadyRegistered < ::StandardError
    end
    class UnknownHandlerError < ::StandardError
    end
    
    module ClassMethods
      protected
        def on message_class, &block
          if handlers_store.key?(message_class)
            raise HandlerAlreadyRegistered.new("Handler for message '#{message_class}' already registered") 
          end
          
          method_name = "on-#{message_class.name}-message"
          define_method method_name, &block
          handlers_store[message_class] = method_name
        end
        
      private
        def handlers_store
          @registered_handlers ||= {}
        end
    end
    
    module InstanceMethods
      def registered_message_handlers
        handlers_store.keys
      end
      
      def can_handle_message?(message)
        handlers_store.key? message.class
      end
      
      def handle_message(message)
        raise UnknownHandlerError.new "Handler for message '#{message.class}' not found." unless can_handle_message?(message)
        handler = handlers_store[message.class]
        send(handler, message)
      end
      
      private
        def handlers_store
          @handlers_store ||= self.class.send(:handlers_store)
        end
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end
