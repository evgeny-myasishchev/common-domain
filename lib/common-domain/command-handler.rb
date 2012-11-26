module CommonDomain
  class CommandHandler
    include Infrastructure::MessagesHandler
    attr_reader :repository
    def initialize(repository = nil)
      @repository = repository
    end
    
    def self.on message_class, options = {}, &block
      super(message_class, &block)
      if options[:begin_work]
        # TODO: replace original messages handler method
        # In the method start work, begin_work and call original method with the work.
        # Also message_handler_name should be corrected to return method name that is really valid method name
      end
    end
  end
end