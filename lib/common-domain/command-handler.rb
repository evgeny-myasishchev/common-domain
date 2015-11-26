module CommonDomain
  class CommandHandler
    extend Forwardable
    include Messages::MessagesHandler    

    def_delegators :persistence_factory, :begin_unit_of_work, :create_repository

    attr_reader :persistence_factory
    def initialize(persistence_factory = nil)
      @persistence_factory = persistence_factory
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
      def handle command_class, id: :id
        raise ArgumentError.new "Can not define handler. The command '#{command_class}' does not provide required '#{id}' attribute." unless 
          command_class.attribute_names.include?(id)
        
        definition = HandleDefinition.new command_class
        on command_class do |command|
          raise "aggregate_class is not defined for command '#{command_class}' handler definition" unless definition.aggregate_class
          repository = persistence_factory.create_repository
          aggregate = repository.get_by_id definition.aggregate_class, command.attribute(id)
          arguments = collect_arguments definition.aggregate_class, command, id, definition.method_name
          result = aggregate.send(definition.method_name, *arguments)
          repository.save aggregate, command.headers
          result
        end
        definition
      end
    end
    
    private def collect_arguments(aggregate_class, command, id_attr, method_name)
      action = aggregate_class.instance_method(method_name)
      return [] unless action.parameters.length
      
      # aggregate_id is skipped since it's used to find the aggregate
      command_attributes = command.attribute_names.to_set.delete(id_attr)
      
      if command_attributes.length > action.parameters.length
        first_extra_attribute = (command_attributes - action.parameters.map { |param| param[1] }).first
        raise ArgumentError.new "Can not map arguments. The command provides '#{first_extra_attribute}' attribute but the '#{method_name}' method does not have a corresponding parameter."
      end
      result = []
      named_args = {}
      action.parameters.each { |param|
        param_kind = param[0] #:req, :opt, :key
        param_name = param[1]
        param_provided = command_attributes.include?(param_name) || command_attributes.include?(param_name.to_s)
        unless param_provided || param_kind == :opt || param_kind == :key
          raise ArgumentError.new "Can not map arguments. The '#{method_name}' method expects '#{param_name}' parameter but the command does not have a corresponding attribute."
        end
        value = command.attribute(param_name)
        if param[0] == :req || param[0] == :opt
          result << value if param_provided
        elsif param[0] == :key
          named_args[param_name] = value if param_provided
        else
          raise "Can not handle param '#{param[1]}' with specification '#{param[0]}"
        end
      }
      result << named_args unless named_args.empty?
      result
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