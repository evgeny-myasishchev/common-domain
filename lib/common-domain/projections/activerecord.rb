module CommonDomain::Projections
  module ActiveRecord
    class Projection
      def initialize(model)
        
      end
    end
    
    module ClassMethods
      def setup
        # Schema is initialized with rake task.
      end
    
      def cleanup!
        # TODO: Implement
      end
    
      def rebuild_required?
        # TODO: Implement
        false
      end
    
      def setup_required?
        # TODO: Implement
        false
      end
    end
    
    module InstanceMethods
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.extend         CommonDomain::Infrastructure::MessagesHandler
      receiver.send :include, InstanceMethods
    end
  end
end