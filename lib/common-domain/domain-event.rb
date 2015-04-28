module CommonDomain
  class DomainEvent < CommonDomain::Messages::Message
    module DSL
      def self.included(receiver)
        receiver.class_eval do
          include CommonDomain::Messages::DSL
          setup_dsl message_base_class: CommonDomain::DomainEvent, dsl_module: CommonDomain::DomainEvent::DSL

          class << self
            alias_method :event, :message
            alias_method :events_group, :group
          end
        end
      end
    end
  end
end
