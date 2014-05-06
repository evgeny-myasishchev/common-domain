module CommonDomain::Projections
  module ActiveRecord
    require 'active_record'
    
    # The model is used to hold various projection related meta information
    # like version
    class ProjectionsMeta < ::ActiveRecord::Base
      class << self
        def ensure_schema!
          unless table_exists?
            connection.create_table(table_name) do |t|
              t.column :projection_id, :string, null: false
              t.column :version, :integer, null: false
            end
          end
        end
        
        def setup_required?(projection_id)
          
        end
        
        def rebuild_required?(projection_id, version)
          
        end
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