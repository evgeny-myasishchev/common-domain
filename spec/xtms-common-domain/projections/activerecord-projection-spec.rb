require 'spec-helper'

describe CommonDomain::Projections::ActiveRecord do
  include ActiveRecordHelpers
  use_sqlite_activerecord_connection 'ar-projections-spec.sqlite'
  
  class TheProjection < ActiveRecord::Base
    include CommonDomain::Projections::ActiveRecord
  end
  
  subject { TheProjection }
  let(:meta_class) { CommonDomain::Projections::ActiveRecord::ProjectionsMeta }
  
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
  
  describe "cleanup!" do
    class ActiveRecordProjectionCleanupSpec < ActiveRecord::Base
      include CommonDomain::Projections::ActiveRecord
      def self.ensure_schema!
        unless connection.table_exists? table_name
          connection.create_table(table_name) do |t|
            t.column :name, :string
          end
        end
      end
    end
    subject { ActiveRecordProjectionCleanupSpec }
    let(:model_class) { ActiveRecordProjectionCleanupSpec }
    
    before(:each) do
      subject.projection version: 120, identifier: "projection-120"
      subject.setup
      model_class.ensure_schema!
      model_class.create! name: 'Name 1'
      model_class.create! name: 'Name 2'
      model_class.create! name: 'Name 3'
      subject.cleanup!
    end
    
    it "should delete all data" do
      model_class.count.should eql 0
    end
    
    it "should delete corresponding meta record" do
      meta_class.find_by(projection_id: 'projection-120').should be_nil
    end
  end
  
  describe "rebuild_required?" do
    before(:each) do
      subject.projection version: 130, identifier: "projection-130"
    end
    
    it "should use meta model to define that" do
      meta_class.should_receive(:rebuild_required?).with('projection-130', 130).and_return(true)
      subject.rebuild_required?.should be_true
    end
  end
  
  describe "setup_required?" do
    before(:each) do
      subject.projection version: 130, identifier: "projection-130"
    end
    
    it "should use meta model to define that" do
      meta_class.should_receive(:setup_required?).with('projection-130').and_return(true)
      subject.setup_required?.should be_true
    end
  end
end