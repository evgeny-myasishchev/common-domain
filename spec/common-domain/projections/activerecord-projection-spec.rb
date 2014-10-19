require 'spec-helper'

describe CommonDomain::Projections::ActiveRecord do
  include ActiveRecordHelpers
  establish_activerecord_connection
  
  class TheProjection < ActiveRecord::Base
    include CommonDomain::Projections::ActiveRecord
  end
  
  subject { TheProjection }
  let(:meta_class) { CommonDomain::Projections::ActiveRecord::ProjectionsMeta }
  
  before(:each) do
    c = ActiveRecord::Base.connection
    c.drop_table 'projections_meta' if c.table_exists? 'projections_meta'
  end
  
  describe "create_projection" do
    class ProjectionConfigSpec < ActiveRecord::Base
      include CommonDomain::Projections::ActiveRecord
    end
    subject { ProjectionConfigSpec.create_projection }
    
    it "should create and configure instance of the projection class" do
      expect(subject).to be_a CommonDomain::Projections::ActiveRecord::Projection
    end
    
    it "should invoke the projection block in context of projection class" do
      ProjectionConfigSpec.projection do
        def self.get_the_self
          self
        end
        
        def get_the_self
          self
        end
      end
      expect(subject.class.get_the_self).to eql subject.class
      expect(subject.get_the_self).to eql subject
    end
    
    it "should supply create_projection args to the projection configuration block" do
      ProjectionConfigSpec.projection do |*args|
        @method_args = args
        def self.the_args
          @method_args
        end
      end
      projection = ProjectionConfigSpec.create_projection 100, "arg-2", "arg-3"
      expect(projection.class.the_args).to eql [100, 'arg-2', 'arg-3']
    end
    
    it "should have default config" do
      expect(subject.config).to eql version: 0, identifier: 'projection_config_specs'
    end
    
    describe "configured" do
      before(:each) do
        ProjectionConfigSpec.projection version: 100, identifier: 'some-identifier-100'
      end
      
      it "should assign specific values" do
        expect(subject.config).to eql version: 100, identifier: 'some-identifier-100'
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
      expect(meta_class).to receive(:ensure_schema!).and_call_original
      ProjectionConfigSetupSpec1.create_projection.setup
    end
    
    it "should raise error if initialized before" do
      expect(lambda { subject.create_projection.setup }).to raise_error("Projection 'projection-110' has already been initialized.")
    end
    
    it "should record corresponding record" do
      meta = meta_class.find_by projection_id: 'projection-110'
      expect(meta).not_to be_nil
      expect(meta.version).to eql 110
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
      expect(model_class.count).to eql 0
    end
    
    it "should delete corresponding meta record" do
      expect(meta_class.find_by(projection_id: 'projection-120')).to be_nil
    end
  end
  
  describe "rebuild_required?" do
    before(:each) do
      allow(meta_class).to receive(:table_exists?) { true }
      subject.projection version: 130, identifier: "projection-130"
    end
    
    it "should use meta model to define that" do
      expect(meta_class).to receive(:rebuild_required?).with('projection-130', 130).and_return(true)
      expect(subject.create_projection.rebuild_required?).to be_truthy
    end
        
    it "should be false if meta model table does not exist" do
      expect(meta_class).to receive(:table_exists?) { false }
      expect(subject.create_projection.rebuild_required?).to be_falsey
    end
  end
  
  describe "setup_required?" do
    before(:each) do
      subject.projection version: 130, identifier: "projection-130"
      allow(meta_class).to receive(:table_exists?) { true }
    end
    
    it "should use meta model to define that" do
      expect(meta_class).to receive(:setup_required?).with('projection-130').and_return(true)
      expect(subject.create_projection.setup_required?).to be_truthy
    end
    
    it "should be true if meta model table does not exist" do
      expect(meta_class).to receive(:table_exists?) { false }
      expect(subject.create_projection.setup_required?).to be_truthy
    end
  end
  
  describe "events_handling" do
    module ArProjectionSpecEvents
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
        
        on ArProjectionSpecEvents::EmployeeCreated do |event|
          handled_events << event
        end
        
        on ArProjectionSpecEvents::EmployeeRemoved do |event|
          handled_events << event
        end
      end
    end
    
    subject { EventsHandlingSpec.create_projection }
    
    it "should create class once" do
      expect(subject.class).to eql EventsHandlingSpec.create_projection.class
    end
    
    it "should assign const to the class" do
      expect(subject.class.name).to eql 'EventsHandlingSpec::Projection'
    end
    
    it "should handle events" do
      e1 = ArProjectionSpecEvents::EmployeeCreated.new('e-1')
      e2 = ArProjectionSpecEvents::EmployeeChanged.new('e-2')
      e3 = ArProjectionSpecEvents::EmployeeRemoved.new('e-3')
      expect(subject.can_handle_message?(e1)).to be_truthy
      expect(subject.can_handle_message?(e2)).to be_falsey
      expect(subject.can_handle_message?(e3)).to be_truthy
      subject.handle_message(e1)
      subject.handle_message(e3)
      expect(subject.handled_events.length).to eql(2)
      expect(subject.handled_events).to include(e1)
      expect(subject.handled_events).to include(e3)
    end
  end
end