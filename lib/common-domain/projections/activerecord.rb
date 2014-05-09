module CommonDomain::Projections
  module ActiveRecord
    require 'active_record'
    
    # The model is used to hold various projection related meta information
    # like version
    class ProjectionsMeta < ::ActiveRecord::Base
      class << self
        def ensure_schema!
          unless connection.table_exists? table_name
            connection.create_table(table_name) do |t|
              t.column :projection_id, :string, null: false
              t.column :version, :integer, null: false
            end
          end
        end
        
        def setup_required?(projection_id)
          exists? projection_id: projection_id
        end
        
        def rebuild_required?(projection_id, version)
          meta = find_by projection_id: projection_id
          return true if version > meta.version
          return false if version == meta.version
          raise "Downgrade is not supported for projection #{projection_id}. Last known version is #{meta.version}. Requested projection version was #{version}."
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
      
      def setup
        ProjectionsMeta.ensure_schema!
        raise "Projection '#{config[:identifier]}' has already been initialized." if ProjectionsMeta.exists?(projection_id: config[:identifier])
        ProjectionsMeta.create! projection_id: config[:identifier], version: config[:version]
      end
      
      def cleanup!
        transaction do
          delete_all
          ProjectionsMeta.where(projection_id: config[:identifier]).delete_all
        end
      end
      
      def rebuild_required?
        ProjectionsMeta.rebuild_required?(config[:identifier], config[:version])
      end
      
      def setup_required?
        ProjectionsMeta.setup_required?(config[:identifier])
      end
    end
    
    def self.included(receiver)
      raise "The module #{self} can not be included. It must be extended. The receiver was: #{receiver}."
    end
    
    def self.extended(receiver)
      receiver.send :include, CommonDomain::Projections::Base
      receiver.extend ClassMethods
    end
  end
end