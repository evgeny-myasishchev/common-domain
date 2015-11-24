module CommonDomain
  module Persistence
    require_relative 'persistence/aggregates-builder'
    require_relative 'persistence/repository'
    require_relative 'persistence/snapshots'
    require_relative 'persistence/event-store/repository'
    
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

    module EventStore
      class RepositoryFactory
        def initialize(event_store, builder, snapshots_repository = nil)
          @event_store, @builder, @snapshots_repository = event_store, builder, snapshots_repository
        end
        
        def create_repository
          Repository.new @event_store, @builder, @snapshots_repository
        end
      end
    end
  end
end