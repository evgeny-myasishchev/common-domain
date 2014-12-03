require 'spec-helper'

describe CommonDomain::DomainContext do
  let(:described_class) {
    Class.new(CommonDomain::DomainContext) do
      def with_projections(&block)
        bootstrap_projections &block
      end
    end
  }
  subject { 
    c = described_class.new 
    c.with_event_bus
    c
  }
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
      expect(subject.read_store_database_config).to eql specs['read-store']
      expect(subject.event_store_database_config).to eql specs['event-store']
    end
    
    it "should use fallback spec if specific not found" do
      specs = {
        'fallback' => {
          fallback_spec: true
        }
      }
      subject.with_database_configs(specs, 'fallback')
      expect(subject.read_store_database_config).to eql specs['fallback']
      expect(subject.event_store_database_config).to eql specs['fallback']
    end
    
    it "should correct sqlite3 adapter name if using fallback config" do
      specs = {
        'fallback' => {
          'adapter' => 'sqlite3',
          fallback_spec: true
        }
      }
      subject.with_database_configs(specs, 'fallback')
      expect(subject.read_store_database_config['adapter']).to eql 'sqlite'
      expect(subject.event_store_database_config['adapter']).to eql 'sqlite'
    end
    
    it "should not modify instance of original fallback spec" do
      specs = {
        'fallback' => {
          'adapter' => 'sqlite3',
          fallback_spec: true
        }
      }
      subject.with_database_configs(specs, 'fallback')
      expect(specs['fallback']['adapter']).to eql 'sqlite3'
    end
  end
  
  describe "with_projections_initialization" do
    it "should initialize_projections but not clean all" do
      expect(subject).to receive(:initialize_projections).with(:cleanup_all => false) { }
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
      allow(rm1).to receive_messages(:setup => nil, :cleanup! => nil, :rebuild_required? => false, :setup_required? => false, :can_handle_message? => false)
      allow(rm2).to receive_messages(:setup => nil, :cleanup! => nil, :rebuild_required? => false, :setup_required? => false, :can_handle_message? => false)
      allow(rm3).to receive_messages(:setup => nil, :cleanup! => nil, :rebuild_required? => false, :setup_required? => false, :can_handle_message? => false)

      allow(subject).to receive(:event_store) { event_store }
      expect(persistence_engine).to receive(:for_each_commit) do |&block|
        block.call double(:commit1, :events => [double(:event, :body => event11), double(:event, :body => event12)])
        block.call double(:commit2, :events => [double(:event, :body => event21), double(:event, :body => event22)])
      end
      register_rmx
    end
    
    it "should not publish events if projections needs rebuild" do
      reset persistence_engine
      expect(persistence_engine).not_to receive(:for_each_commit)
      subject.initialize_projections cleanup_all: false
    end
    
    context ":cleanup_all => false" do
      it "should cleanup and setup projections that needs rebuild" do
        expect(rm1).to receive(:rebuild_required?) { true }
        expect(rm3).to receive(:rebuild_required?) { true }
        expect(rm1).to receive(:cleanup!)
        expect(rm3).to receive(:cleanup!)
        expect(rm1).to receive(:setup)
        expect(rm3).to receive(:setup)
        subject.initialize_projections cleanup_all: false
      end
      
      it "should dispatch events to all projections that has been rebuilt" do
        expect(rm1).to receive(:rebuild_required?) { true }
        expect(rm3).to receive(:rebuild_required?) { true }
        all_events.each { |e| 
          expect(rm1).to receive(:can_handle_message?).with(e).and_return(true)
          expect(rm1).to receive(:handle_message).with(e).and_return(true)
          expect(rm3).to receive(:can_handle_message?).with(e).and_return(true)
          expect(rm3).to receive(:handle_message).with(e).and_return(true)
        }
        
        subject.initialize_projections cleanup_all: false
      end
      
      it "should setup all projections that needs setup" do
        expect(rm1).to receive(:setup_required?) { true }
        expect(rm3).to receive(:setup_required?) { true }
        expect(rm1).to receive(:setup)
        expect(rm3).to receive(:setup)
        subject.initialize_projections cleanup_all: false
      end
      
      it "should dispatch events to all projections that has been setup" do
        expect(rm1).to receive(:setup_required?) { true }
        expect(rm3).to receive(:setup_required?) { true }

        all_events.each { |e| 
          expect(rm1).to receive(:can_handle_message?).with(e).and_return(true)
          expect(rm1).to receive(:handle_message).with(e).and_return(true)
          expect(rm3).to receive(:can_handle_message?).with(e).and_return(true)
          expect(rm3).to receive(:handle_message).with(e).and_return(true)
        }
        
        subject.initialize_projections cleanup_all: false
      end
    end
    
    context ":cleanup_all => true" do
      it "should cleanup and setup all projections" do
        expect(rm1).to receive(:cleanup!)
        expect(rm2).to receive(:cleanup!)
        expect(rm3).to receive(:cleanup!)
        expect(rm1).to receive(:setup)
        expect(rm2).to receive(:setup)
        expect(rm3).to receive(:setup)
        subject.initialize_projections cleanup_all: true
      end
      
      it "should dispatch events to all projections" do
        all_events.each { |e| 
          expect(rm1).to receive(:can_handle_message?).with(e).and_return(true)
          expect(rm1).to receive(:handle_message).with(e).and_return(true)
          expect(rm2).to receive(:can_handle_message?).with(e).and_return(true)
          expect(rm2).to receive(:handle_message).with(e).and_return(true)
          expect(rm3).to receive(:can_handle_message?).with(e).and_return(true)
          expect(rm3).to receive(:handle_message).with(e).and_return(true)
        }
        subject.initialize_projections cleanup_all: true
      end
    end
  end
  
  describe "with_dispatch_undispatched_commits" do
    it "should dispatch_undispatched" do
      event_store = double(:event_store)
      allow(subject).to receive(:event_store) {event_store}
      expect(event_store).to receive(:dispatch_undispatched)
      subject.with_dispatch_undispatched_commits
    end
  end
  
  describe 'repository_factory' do
    let(:snapshots_repo) { double(:snapshots_repo) }
    before(:each) do
      described_class.class_eval do
        def with_event_store
          bootstrap_event_store do |with|
            with.in_memory_persistence
            with.log4r_logging
          end
        end
      end
      subject.with_event_store
      subject.with_snapshots snapshots_repo
    end
    
    it 'should return a new instance of the event store RepositoryFactory' do
      factory = double(:factory)
      expect(CommonDomain::Persistence::EventStore::RepositoryFactory).to receive(:new)
        .with(subject.event_store, instance_of(CommonDomain::Persistence::AggregatesBuilder), snapshots_repo)
        .and_return(factory).once
      expect(subject.repository_factory()).to be(factory)
      expect(subject.repository_factory()).to be(factory)
    end
  end
end