require 'spec-helper'

describe CommonDomain::Projections::ActiveRecord do
  include ActiveRecordHelpers
  use_sqlite_activerecord_connection 'ar-projections-spec.sqlite'
  
  class TheProjection < ActiveRecord::Base
    include CommonDomain::Projections::ActiveRecord
  end
  
  subject { TheProjection }
  
  it "should be a base projection" do
    TheProjection.should be_a CommonDomain::Projections::Base
  end
  
  describe "projection config" do
    class ProjectionConfigSpec < ActiveRecord::Base
      include CommonDomain::Projections::ActiveRecord
    end
    subject { ProjectionConfigSpec }
    
    it "should have default config" do
      subject.config.should eql version: 0, identifier: 'projection_config_specs'
    end
    
    describe "configured" do
      before(:each) do
        subject.projection version: 100, identifier: 'some-identifier-100'
      end
      
      it "should assign specific values" do
        subject.config.should eql version: 100, identifier: 'some-identifier-100'
      end
    end
  end
end