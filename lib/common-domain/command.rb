module CommonDomain
  class CommandClassMissingError < ::StandardError
    def initialize
      super("Can not determine command class because class_name parameter not found.")
    end
  end

  class Command < CommonDomain::Messages::Message
    attr_reader :headers
    
    def initialize(*args)
      @headers = {}
      super
    end
    
    def ==(other)
      super && headers.all? { |key, value| value == other.headers[key] }
    end
    
    protected
      def initialize_by_hash hash
        @headers = hash.key?(:headers) ? hash.delete(:headers) : {}
        super hash.key?(:attributes) ? hash[:attributes] : hash
      end
      
      def handle_missing_value! attr_name
        # Commands can be initialized with missing attributes
        # Custom validation logic (like ActiveModel::Validations) can be applied to make sure required attributes provided
      end
      
    module DSL
      def self.included(receiver)
        receiver.class_eval do
          include CommonDomain::Messages::DSL
          setup_dsl message_base_class: CommonDomain::Command, dsl_module: CommonDomain::Command::DSL

          class << self
            alias_method :command, :message
            alias_method :commands_group, :group
          end
        end
      end
    end
  end
end