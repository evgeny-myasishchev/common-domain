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
          return true unless table_exists?
          exists? projection_id: projection_id
        end
        
        def rebuild_required?(projection_id, version)
          return false unless table_exists?
          meta = find_by projection_id: projection_id
          return true if version > meta.version
          return false if version == meta.version
          raise "Downgrade is not supported for projection #{projection_id}. Last known version is #{meta.version}. Requested projection version was #{version}."
        end
      end
    end
    
    class Projection
      include Base
      
      attr_reader :config, :model
      
      def configure(model, config)
        @model = model
        @config = config
      end
      
      def setup
        ProjectionsMeta.ensure_schema!
        raise "Projection '#{config[:identifier]}' has already been initialized." if ProjectionsMeta.exists?(projection_id: config[:identifier])
        ProjectionsMeta.create! projection_id: config[:identifier], version: config[:version]
      end
      
      def cleanup!
        model.transaction do
          model.delete_all
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
    
    module ClassMethods
      def projection_class
        @projection_class ||= Class.new(Projection)
      end
      
      def projection_config
        @projection_config ||= default_projection_config
      end
      
      # Configure the projection. Available options:
      # - version <number> - The version of the projection. Should be incremented if projection the projection needs rebubild.
      #   The rebuild is usually required if schema has changed.
      # - identifier <value> - The identifier or the projection. Usually assigned automatically based on the AR model table name
      def projection(projection_config = {}, &block)
        @projection_config = default_projection_config.merge projection_config
        projection_class.class_eval &block if block_given?
      end
      
      def default_projection_config
        {
          version: 0,
          identifier: self.table_name
        }
      end
      
      def create_projection
        projection = projection_class.new
        projection.configure self, projection_config
        projection
      end
    end
    
    def self.included(receiver)
      receiver.extend ClassMethods
    end
  end
end