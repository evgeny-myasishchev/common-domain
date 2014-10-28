module CommonDomain::Persistence
  class Snapshots
    def initialize(snapshots_repository)
      @snapshots_repository = snapshots_repository
    end
    
    # Get the snapshot for given aggregate using the repository.
    def get_snapshot(aggregate_id)
    end
    
    # Uses snapshots policy for given aggregate to determine if a snapshot should be added.
    # Uses snapshots repository to add the snapshot.
    def process_committed(aggregate)
    end
    
    class SnapshotsRepository
      # Get the snapshot or nil
      def get(aggregate_id)
        raise 'Not implemented'
      end
      
      # Add the snapshot for given aggregate
      def add(aggregate)
        raise 'Not implemented'
      end
    end
    
    class SnapshotsPolicy
      # Initializes the snapshots policy. Given block will be invoked with the aggregate as a first argument.
      # The block should return true if the snapshot should be added.
      def initialize(&block)
        
      end
      
      # Uses provided block (with initializer) to determine if a snapshot should be added for the given aggregate
      def add_snapshot?(aggregate)
        
      end
    end
  end
end