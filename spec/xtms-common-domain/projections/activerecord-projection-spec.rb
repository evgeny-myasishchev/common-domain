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
  
  describe "setup" do
    let(:meta_class) { CommonDomain::Projections::ActiveRecord::ProjectionsMeta }
    
    before(:each) do
      subject.projection version: 110, identifier: "projection-110"
      subject.setup
    end
    
    after(:each) do
      meta_class.where(projection_id: 'projection-110').delete_all
    end
    
    it "should setup schema of the meta " do
      class ProjectionConfigSetupSpec1 < ActiveRecord::Base
        include CommonDomain::Projections::ActiveRecord
      end
      meta_class.should_receive(:ensure_schema!).and_call_original
      ProjectionConfigSetupSpec1.setup
    end
    
    it "should raise error if initialized before" do
      lambda { subject.setup }.should raise_error("Projection 'projection-110' has already been initialized.")
    end
    
    it "should record corresponding record" do
      meta = meta_class.find_by projection_id: 'projection-110'
      meta.should_not be_nil
      meta.version.should eql 110
    end
  end
end