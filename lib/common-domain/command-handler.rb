module CommonDomain
  class CommandHandler
    include Infrastructure::MessagesHandler
    attr_reader :repository
    def initialize(repository = nil)
      @repository = repository
    end
    
    class << self
      # Defines command hanler. 
      # Samples:
      # # The most simplest way
      # on EmployeeHired do |command|
      # end
      #
      # # Handler with headers
      # on EmployeeHired do |command, headers|
      # end
    
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
      action.parameters.map { |param| 
        param_name = param[1]
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