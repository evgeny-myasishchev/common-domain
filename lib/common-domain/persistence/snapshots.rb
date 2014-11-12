module CommonDomain::Persistence
  module Snapshots
    class Snapshot
      attr_reader :id, :version, :data
      
      def initialize(id, version, data)
        @id, @version, @data = id, version, data
      end
      
      def ==(other)
        id == other.id && 
        version == other.version &&
        data == other.data
      end
    
      def eql?(other)
        self == other
      end
    end
    
    class SnapshotsRepository
      # Get the snapshot or nil
      def get(aggregate_id)
        raise 'Not implemented'
      end
      
      # Add the snapshot
      def add(snapshot)
        raise 'Not implemented'
      end
    end
  end
end