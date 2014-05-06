module CommonDomain::Projections
  module ActiveRecord
    require 'active_record'
    
    # The model is used to hold various projection related meta information
    # like version
    class ProjectionsMeta < ::ActiveRecord::Base
      def self.ensure_schema!
        
      end
    end
    
    module ClassMethods
      def config
        @config ||= default_config
      end
      
      # Configure the projection. Available options:
      # - version <number> - The version of the projection. Should be incremented if projection the projection needs rebubild.
      #   The rebuild is usually required if schema has changed.
      # - identifier <value> - The identifier or the projection. Usually assigned automatically based on the AR model table name
      def projection(config = {})
        @config = default_config.merge config
      end
      
      def default_config
        {
          version: 0,
          identifier: self.table_name
        }
      end
    end
    
    def self.included(receiver)
      receiver.extend CommonDomain::Projections::Base
      receiver.extend ClassMethods
    end
  end
end