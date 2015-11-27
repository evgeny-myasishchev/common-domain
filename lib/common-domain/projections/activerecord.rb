module CommonDomain::Projections
  require_relative 'base'
  
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
  module ActiveRecord
    require 'active_record'
    
    module ProjectionInstanceMethods
      def initialize(model_class)
        @model_class = model_class
      end
      
      def identifier
        @model_class.name
      end
      
      def purge!
        logger.warn "Purging projection: #{self}"
        @model_class.delete_all
      end
    end
    
    module ClassMethods
      def projection(&block)
        @projection_init_block = block
        self.send(:remove_const, 'Projection') unless @projection_class.nil?
        @projection_class = nil
      end
      
      def create_projection(*args)
        @projection_class ||= begin
          projection_class = Class.new do
            include Base
            include ProjectionInstanceMethods
            
            def logger
              @logger ||= CommonDomain::Logger.get(self.class.name)
            end
          end
          projection_class.class_exec(*args, &@projection_init_block) if @projection_init_block
          self.const_set(:Projection, projection_class)
          projection_class
        end
        @projection_class.new self
      end
    end
    
    def self.included(receiver)
      receiver.extend ClassMethods
    end
  end
end