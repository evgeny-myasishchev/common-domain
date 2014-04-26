module CommonDomain::Projections
  module ActiveRecord
    class Projection < CommonDomain::Projections::Base
      attr_reader :model_class
      def initialize(model_class)
        @model_class = model_class
      end
    end
    
    module ClassMethods
      def create_projection
        Projection.new self
      end
    end
    
    module InstanceMethods
      
    end
    
    def self.included(receiver)
      receiver.extend ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end