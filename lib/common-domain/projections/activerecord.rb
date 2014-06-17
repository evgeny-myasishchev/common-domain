module CommonDomain::Projections
  
  # Contains basic stuff required to create a projection based on the ActiveRecord model.
  # Sample:
  # class Employee < ActiveRecord::Base
  #   include CommonDomain::Projections::ActiveRecord
  # 
  #   projection do
  #     on Events::EmployeeCreated do |event|
  #       Employee.create! employee_id: event.aggregate_id, name: event.name
  #     end
  #   
  #     on Events::EmployeeRenamed do |event|
  #       rec = Employee.find_by(employee_id: event.aggregate_id)
  #       rec.name = event.name
  #       rec.save!
  #     end
  #   
  #     on Events::EmployeeRemoved do |event|
  #       Employee.where(employee_id: event.aggregate_id).delete_all
  #     end
  #   end
  # end
  #
  # To register the projection:
  # def with_projections
  #   bootstrap_projections do |projections|
  #     projections.register :employee, Employee.create_projection
  #   end
  # end
  # 
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
          !exists? projection_id: projection_id
        end
        
        def rebuild_required?(projection_id, version)
          return false unless table_exists?
          meta = find_by projection_id: projection_id
          return false if meta.nil?
          return true if version > meta.version
          return false if version == meta.version
          raise "Downgrade is not supported for projection #{projection_id}. Last known version is #{meta.version}. Requested projection version was #{version}."
        end
      end
    end
    
    class Projection
      include Base
      
      attr_reader :config, :model
      
      def initialize(model, config)
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
        result = ProjectionsMeta.rebuild_required?(config[:identifier], config[:version])
        puts "rebuild_required?(#{config[:identifier]}, #{config[:version]}): #{result}"
        result
      end
      
      def setup_required?
        result = ProjectionsMeta.setup_required?(config[:identifier])
        puts "setup_required?(#{config[:identifier]}): #{result}"
        result
      end
    end
    
    module ClassMethods
      def projection_config
        @projection_config ||= default_projection_config
      end
      
      # Configure the projection. Available options:
      # - version <number> - The version of the projection. Should be incremented if projection the projection needs rebubild.
      #   The rebuild is usually required if schema has changed.
      # - identifier <value> - The identifier or the projection. Usually assigned automatically based on the AR model table name
      def projection(projection_config = {}, &block)
        @projection_config = default_projection_config.merge projection_config
        @projection_init_block = block
        self.send(:remove_const, 'Projection') unless @projection_class.nil?
        @projection_class = nil
      end
      
      def default_projection_config
        {
          version: 0,
          identifier: self.table_name
        }
      end
      
      def create_projection(*args)
        @projection_class ||= begin
          projection_class = Class.new(Projection)
          projection_class.class_exec(*args, &@projection_init_block) if @projection_init_block
          self.const_set("Projection", projection_class)
          projection_class
        end
        @projection_class.new self, projection_config
      end
    end
    
    def self.included(receiver)
      receiver.extend ClassMethods
    end
  end
end