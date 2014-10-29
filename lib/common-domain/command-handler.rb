module CommonDomain
  class CommandHandler
    include Infrastructure::MessagesHandler
    attr_reader :repository
    def initialize(repository = nil)
      @repository = repository
    end
    
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
    def self.handle command_class
      HandleSyntax.new self, command_class
    end
    
    class HandleSyntax
      attr_reader :aggregate_class
      
      def initialize(handler, command_class)
        @handler, @command_class = handler, command_class
      end
      
      def with(aggregate_class)
        raise ArgumentError.new 'aggregate_class should not be nil' if aggregate_class.nil?
        that = self
        @handler.on @command_class do |command|
          aggregate = work.get_by_id aggregate_class, command.aggregate_id
          aggregate.send(that.method_name, command)
        end
        self
      end
      
      def using(method_name)
        @method_name = method_name
      end
      
      def method_name
        @method_name ||= self.class.resolve_aggregate_method_name @command_class
      end
      
      class << self
        def resolve_aggregate_method_name command_class
          underscore command_class.name.split('::').last
        end
        
        private
          AcronymRegex = /(?=a)b/
      
          # Taken from ActiveSupport. It may be not available if using outside of the RoR
          # File activesupport/lib/active_support/inflector/methods.rb, line 90
          def underscore(camel_cased_word)
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
end