module CommonDomain
  class Entity
    include Infrastructure::MessagesHandler
    
    attr_reader :aggregate, :aggregate_id, :entity_id
    
    def initialize(aggregate)
      @aggregate = aggregate
      @aggregate_id = aggregate.aggregate_id
    end
    
    def apply_event(event)
      handle_message(event)
    end
    
    protected
      def raise_event(event)
        aggregate.send(:raise_event, event)
      end
  end
end
