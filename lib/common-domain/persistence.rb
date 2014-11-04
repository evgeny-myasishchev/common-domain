module CommonDomain
  module Persistence
    # Raised when Aggregate can not be found by given id.
    class AggregateNotFoundError < StandardError
      def initialize(aggregate_class, aggregate_id)
        @aggregate_class = aggregate_class
        @aggregate_id = aggregate_id
      end
    
      def message
        "Aggregate '#{@aggregate_class.name}' with id '#{@aggregate_id}' was not found."
      end
    end    
    
    autoload :AggregatesBuilder, 'common-domain/persistence/aggregates-builder'
    module EventStore
      autoload :Repository, 'common-domain/persistence/event-store/repository'
    end
    autoload :Repository, 'common-domain/persistence/repository'
    autoload :Snapshots, 'common-domain/persistence/snapshots'
  end
end