module CommonDomain::Projections
  module ActiveRecord
    require 'active_record'
    
    # The model is used to hold various connection related meta information
    # like version
    class ProjectionsMeta < ::ActiveRecord::Base
      def self.ensure_schema!
        
      end
    end
    
    def self.included(receiver)
      receiver.extend CommonDomain::Projections::Base
    end
  end
end