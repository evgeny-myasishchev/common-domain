module CommonDomain::Persistence
  module Snapshots
    class Snapshot
      attr_reader :id, :version, :data
      
      def initialize(id, version, data)
        @id, @version, @data = id, version, data
      end
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
    
    class CommitsHandler
      #
      # Uses snapshots repository to add the snapshot if needed.
      #
      def process_committed(aggregate)
      end
    end
  end
end