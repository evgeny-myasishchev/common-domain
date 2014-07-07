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
    # # Handler with headers wrapped into work
    # on EmployeeHired, begin_work: true do |work, command, headers|
    # end
    
    def self.on message_class, options = {}, &block
      super(message_class, &block)
      if options[:begin_work]
        handler_method_name = message_handler_name message_class
        handler_method = instance_method handler_method_name
        define_method handler_method_name do |*args|          
          bound_handler_method = handler_method.bind(self)
          message = args[0]
          repository.begin_work message.headers do |work|
            args_number = bound_handler_method.arity
            bound_handler_method.call(work, args[0]) if args_number == 2
            bound_handler_method.call(work, args[0], args[1]) if args_number == 3
            raise ArgumentError.new "#{message_class} handler block should have 2 or 3 arguments: work, message and optionally headers. Got: #{args_number}."
          end
        end
      end
    end
  end
end