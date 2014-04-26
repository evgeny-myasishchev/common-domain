require 'spec-helper'

describe CommonDomain::Projections::ActiveRecord do
  require 'active_record'
  class TheProjection < ActiveRecord::Base
    include CommonDomain::Projections::ActiveRecord
  end
  
  describe "self.create_projection" do
    subject { TheProjection.create_projection }
    it "should return an instance of the Projection" do
      subject.should be_instance_of(described_class::Projection)
    end
    
    it "should initialize the projection with corresponding model class" do
      subject.model_class.should be TheProjection
    end
  end
end