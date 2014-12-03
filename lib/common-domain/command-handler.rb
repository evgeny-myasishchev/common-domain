module CommonDomain
  class CommandHandler
    include Infrastructure::MessagesHandler
    attr_reader :repository_factory
    def initialize(repository_factory = nil)
      @repository_factory = repository_factory
    end
    
    class << self
      # Defines command hanler. 
      # Sample:
      # on EmployeeHired do |command|
      # end
      def on(message_class, &block)
        if block.arity != 1
          raise ArgumentError.new "#{message_class} handler block is expected to receive single arguemnt that would be the command itself."
        end
        super
      end
      
      #
      # Defines a handler that automatically dispatches the command to the appropriate aggregate
      # Samples:
      # * handle(AccountCommands::RenameAccount).with(Domain::Account)
      # * handle(AccountCommands::RenameAccount).with(Domain::Account).using(:rename)
      #
      def handle command_class
        definition = HandleDefinition.new command_class
        on command_class do |command|
          raise "aggregate_class is not defined for command '#{command_class}' handler definition" unless definition.aggregate_class
          repository = repository_factory.create_repository
          aggregate = repository.get_by_id definition.aggregate_class, command.aggregate_id
          arguments = collect_arguments definition.aggregate_class, command, definition.method_name
          aggregate.send(definition.method_name, *arguments)
          repository.save aggregate, command.headers
        end
        definition
      end
    end
    
    private def collect_arguments(aggregate_class, command, method_name)
      action = aggregate_class.instance_method(method_name)
      return [] unless action.parameters.length
      if command.attribute_names.length > action.parameters.length
        first_extra_attribute = (command.attribute_names - action.parameters.map { |param| param[1] }).first
        raise ArgumentError.new "Can not map arguments. The command provides '#{first_extra_attribute}' attribute but the '#{method_name}' method does not have a corresponding parameter."
      end
      action.parameters.map { |param| 
        param_name = param[1]
        unless command.attribute_names.include?(param_name)
          raise ArgumentError.new "Can not map arguments. The '#{method_name}' method expects '#{param_name}' parameter but the command does not have a corresponding attribute." 
        end
        command.attribute(param_name)
      }
    end
    
    class HandleDefinition
      attr_reader :aggregate_class
      
      def initialize(command_class)
        @command_class = command_class
      end
      
      def method_name
        @method_name ||= self.class.resolve_aggregate_method_name @command_class
      end
      
      def with(aggregate_class)
        @aggregate_class = aggregate_class
        self
      end
      
      def using(method_name)
        @method_name = method_name
        self
      end
      
      def self.resolve_aggregate_method_name command_class
        underscore command_class.name.split('::').last
      end

      private
        AcronymRegex = /(?=a)b/
    
        # Taken from ActiveSupport. It may be not available if using outside of the RoR
        # File activesupport/lib/active_support/inflector/methods.rb, line 90
        def self.underscore(camel_cased_word)
          word = camel_cased_word.to_s.gsub('::', '/')
          word.gsub!(/Command/,'')
          word.gsub!(/(?:([A-Za-z\d])|^)(#{AcronymRegex})(?=\b|[^a-z])/) { "#{$1}#{$1 && '_'}#{$2.downcase}" }
          word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
          word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
          word.tr!("-", "_")
          word.downcase!
          word
        end
    end
  end
end