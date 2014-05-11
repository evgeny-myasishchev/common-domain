require 'spec-helper'

describe CommonDomain::Projections::ActiveRecord do
  include ActiveRecordHelpers
  use_sqlite_activerecord_connection 'ar-projections-spec.sqlite'
  
  class TheProjection < ActiveRecord::Base
    include CommonDomain::Projections::ActiveRecord
  end
  
  subject { TheProjection }
  let(:meta_class) { CommonDomain::Projections::ActiveRecord::ProjectionsMeta }
  
  describe "create_projection" do
    class ProjectionConfigSpec < ActiveRecord::Base
      include CommonDomain::Projections::ActiveRecord
    end
    subject { ProjectionConfigSpec.create_projection }
    
    it "should create and configure instance of the projection class" do
      subject.should be_a CommonDomain::Projections::ActiveRecord::Projection
    end
    
    it "should have default config" do
      subject.config.should eql version: 0, identifier: 'projection_config_specs'
    end
    
    describe "configured" do
      before(:each) do
        ProjectionConfigSpec.projection version: 100, identifier: 'some-identifier-100'
      end
      
      it "should assign specific values" do
        subject.config.should eql version: 100, identifier: 'some-identifier-100'
      end
    end
  end
  
  describe "setup" do
    before(:each) do
      subject.projection version: 110, identifier: "projection-110"
      subject.create_projection.setup
    end
    
    after(:each) do
      meta_class.where(projection_id: 'projection-110').delete_all
    end
    
    it "should setup schema of the meta " do
      class ProjectionConfigSetupSpec1 < ActiveRecord::Base
        include CommonDomain::Projections::ActiveRecord
      end
      meta_class.should_receive(:ensure_schema!).and_call_original
      ProjectionConfigSetupSpec1.create_projection.setup
    end
    
    it "should raise error if initialized before" do
      lambda { subject.create_projection.setup }.should raise_error("Projection 'projection-110' has already been initialized.")
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
      projection = subject.create_projection
      projection.setup
      model_class.ensure_schema!
      model_class.create! name: 'Name 1'
      model_class.create! name: 'Name 2'
      model_class.create! name: 'Name 3'
      projection.cleanup!
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
      meta_class.stub(:table_exists?) { true }
      subject.projection version: 130, identifier: "projection-130"
    end
    
    it "should use meta model to define that" do
      meta_class.should_receive(:rebuild_required?).with('projection-130', 130).and_return(true)
      subject.create_projection.rebuild_required?.should be_true
    end
        
    it "should be false if meta model table does not exist" do
      meta_class.should_receive(:table_exists?) { false }
      subject.create_projection.rebuild_required?.should be_false
    end
  end
  
  describe "setup_required?" do
    before(:each) do
      subject.projection version: 130, identifier: "projection-130"
      meta_class.stub(:table_exists?) { true }
    end
    
    it "should use meta model to define that" do
      meta_class.should_receive(:setup_required?).with('projection-130').and_return(true)
      subject.create_projection.setup_required?.should be_true
    end
    
    it "should be true if meta model table does not exist" do
      meta_class.should_receive(:table_exists?) { false }
      subject.create_projection.setup_required?.should be_true
    end
  end
  
  describe "events_handling" do
    module Events
      include CommonDomain::DomainEvent::DSL
      event :EmployeeCreated
      event :EmployeeChanged
      event :EmployeeRemoved
    end
    class EventsHandlingSpec < ActiveRecord::Base
      include CommonDomain::Projections::ActiveRecord
      projection do
        def handled_events
          @handled_events ||= []
        end
        
        on Events::EmployeeCreated do |event|
          handled_events << event
        end
        
        on Events::EmployeeRemoved do |event|
          handled_events << event
        end
      end
    end
    
    subject { EventsHandlingSpec.create_projection }
    
    it "should handle events" do
      e1 = Events::EmployeeCreated.new('e-1')
      e2 = Events::EmployeeChanged.new('e-2')
      e3 = Events::EmployeeRemoved.new('e-3')
      subject.can_handle_message?(e1).should be_true
      subject.can_handle_message?(e2).should be_false
      subject.can_handle_message?(e3).should be_true
      subject.handle_message(e1)
      subject.handle_message(e3)
      subject.handled_events.should have(2).items
      subject.handled_events.should include(e1)
      subject.handled_events.should include(e3)
    end
  end
end