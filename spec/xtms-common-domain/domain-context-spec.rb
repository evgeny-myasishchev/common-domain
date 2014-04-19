require 'spec-helper'

describe CommonDomain::DomainContext do
  let(:described_class) {
    Class.new(CommonDomain::DomainContext) do
      def with_projections(&block)
        bootstrap_projections &block
      end
    end
  }
  subject { described_class.new }
  let(:rm1) { double(:read_model_one, :setup => nil) }
  let(:rm2) { double(:read_model_two, :setup => nil) }
  let(:rm3) { double(:read_model_three, :setup => nil) }
  
  def register_rmx
    subject.with_projections do |projections|
      projections.register :rm1, rm1
      projections.register :rm2, rm2
      projections.register :rm3, rm3
    end
  end
  
  describe "with_database_configuration" do
    it "should extract and use read-store and event-store connection specifications" do
      specs = {
        'read-store' => {
          read_store_spec: true
        },
        'event-store' => {
          event_store_spec: true
        }
      }
      subject.with_database_configs(specs)
      subject.read_store_database_config.should eql specs['read-store']
      subject.event_store_database_config.should eql specs['event-store']
    end
    
    it "should use fallback spec if specific not found" do
      specs = {
        'fallback' => {
          fallback_spec: true
        }
      }
      subject.with_database_configs(specs, 'fallback')
      subject.read_store_database_config.should eql specs['fallback']
      subject.event_store_database_config.should eql specs['fallback']
    end
    
    it "should correct sqlite3 adapter name if using fallback config" do
      specs = {
        'fallback' => {
          'adapter' => 'sqlite3',
          fallback_spec: true
        }
      }
      subject.with_database_configs(specs, 'fallback')
      subject.read_store_database_config['adapter'].should eql 'sqlite'
      subject.event_store_database_config['adapter'].should eql 'sqlite'
    end
    
    it "should not modify instance of original fallback spec" do
      specs = {
        'fallback' => {
          'adapter' => 'sqlite3',
          fallback_spec: true
        }
      }
      subject.with_database_configs(specs, 'fallback')
      specs['fallback']['adapter'].should eql 'sqlite3'
    end
  end
  
  describe "with_projections_initialization" do
    it "should initialize_projections but not clean all" do
      subject.should_receive(:initialize_projections).with(:cleanup_all => false) { }
      subject.with_projections_initialization
    end
  end
  
  describe "initialize_projections" do
    let(:persistence_engine) { double(:persistence_engine) }
    let(:event_store) { double(:event_store, :persistence_engine => persistence_engine)}
    let(:event11) { double(:event11) }
    let(:event12) { double(:event12) }
    let(:event21) { double(:event21) }
    let(:event22) { double(:event22) }
    let(:all_events) { [event11, event12, event21, event22]}
    
    before(:each) do
      rm1.stub(:setup => nil, :cleanup! => nil, :rebuild_required? => false, :setup_required? => false, :can_handle_message? => false)
      rm2.stub(:setup => nil, :cleanup! => nil, :rebuild_required? => false, :setup_required? => false, :can_handle_message? => false)
      rm3.stub(:setup => nil, :cleanup! => nil, :rebuild_required? => false, :setup_required? => false, :can_handle_message? => false)

      subject.stub(:event_store) { event_store }
      persistence_engine.should_receive(:for_each_commit) do |&block|
        block.call double(:commit1, :events => [double(:event, :body => event11), double(:event, :body => event12)])
        block.call double(:commit2, :events => [double(:event, :body => event21), double(:event, :body => event22)])
      end
      register_rmx
    end
    
    it "should not publish events if projections needs rebuild" do
      reset persistence_engine
      persistence_engine.should_not_receive(:for_each_commit)
      subject.initialize_projections cleanup_all: false
    end
    
    context ":cleanup_all => false" do
      it "should cleanup and setup projections that needs rebuild" do
        rm1.should_receive(:rebuild_required?) { true }
        rm3.should_receive(:rebuild_required?) { true }
        rm1.should_receive(:cleanup!)
        rm3.should_receive(:cleanup!)
        rm1.should_receive(:setup)
        rm3.should_receive(:setup)
        subject.initialize_projections cleanup_all: false
      end
      
      it "should dispatch events to all projections that has been rebuilt" do
        rm1.should_receive(:rebuild_required?) { true }
        rm3.should_receive(:rebuild_required?) { true }
        all_events.each { |e| 
          rm1.should_receive(:can_handle_message?).with(e).and_return(true)
          rm1.should_receive(:handle_message).with(e).and_return(true)
          rm3.should_receive(:can_handle_message?).with(e).and_return(true)
          rm3.should_receive(:handle_message).with(e).and_return(true)
        }
        
        subject.initialize_projections cleanup_all: false
      end
      
      it "should setup all projections that needs setup" do
        rm1.should_receive(:setup_required?) { true }
        rm3.should_receive(:setup_required?) { true }
        rm1.should_receive(:setup)
        rm3.should_receive(:setup)
        subject.initialize_projections cleanup_all: false
      end
      
      it "should dispatch events to all projections that has been setup" do
        rm1.should_receive(:setup_required?) { true }
        rm3.should_receive(:setup_required?) { true }

        all_events.each { |e| 
          rm1.should_receive(:can_handle_message?).with(e).and_return(true)
          rm1.should_receive(:handle_message).with(e).and_return(true)
          rm3.should_receive(:can_handle_message?).with(e).and_return(true)
          rm3.should_receive(:handle_message).with(e).and_return(true)
        }
        
        subject.initialize_projections cleanup_all: false
      end
    end
    
    context ":cleanup_all => true" do
      it "should cleanup and setup all projections" do
        rm1.should_receive(:cleanup!)
        rm2.should_receive(:cleanup!)
        rm3.should_receive(:cleanup!)
        rm1.should_receive(:setup)
        rm2.should_receive(:setup)
        rm3.should_receive(:setup)
        subject.initialize_projections cleanup_all: true
      end
      
      it "should dispatch events to all projections" do
        all_events.each { |e| 
          rm1.should_receive(:can_handle_message?).with(e).and_return(true)
          rm1.should_receive(:handle_message).with(e).and_return(true)
          rm2.should_receive(:can_handle_message?).with(e).and_return(true)
          rm2.should_receive(:handle_message).with(e).and_return(true)
          rm3.should_receive(:can_handle_message?).with(e).and_return(true)
          rm3.should_receive(:handle_message).with(e).and_return(true)
        }
        subject.initialize_projections cleanup_all: true
      end
    end
  end
  
  describe "with_dispatch_undispatched_commits" do
    it "should dispatch_undispatched" do
      event_store = double(:event_store)
      subject.stub(:event_store) {event_store}
      event_store.should_receive(:dispatch_undispatched)
      subject.with_dispatch_undispatched_commits
    end
  end
end