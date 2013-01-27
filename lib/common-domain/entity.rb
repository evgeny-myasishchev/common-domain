module CommonDomain
  class Entity
    include Infrastructure::MessagesHandler
    
    attr_reader :aggregate
    
    def initialize(aggregate)
      @aggregate = aggregate
    end
    
    def apply_event(event)
      handle_message(event)
    end
    
    protected
      def raise_event(event)
        aggregate.raise_event(event)
      end
  end
end
