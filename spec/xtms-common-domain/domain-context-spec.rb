require 'spec-helper'

describe CommonDomain::DomainContext do
  let(:described_class) {
    Class.new(CommonDomain::DomainContext) do
      def with_read_models(&block)
        bootstrap_read_models &block
      end
    end
  }
  subject { described_class.new }
  let(:rm1) { mock(:read_model_one, :setup => nil) }
  let(:rm2) { mock(:read_model_two, :setup => nil) }
  let(:rm3) { mock(:read_model_three, :setup => nil) }
  
  def register_rmx
    subject.with_read_models do |read_models|
      read_models.register :rm1, rm1
      read_models.register :rm2, rm2
      read_models.register :rm3, rm3
    end
  end
  
  describe "with_read_models_initialization" do
    it "should initialize_read_models but not clean all" do
      subject.should_receive(:initialize_read_models).with(:cleanup_all => false) { }
      subject.with_read_models_initialization
    end
  end
  
  describe "initialize_read_models" do
    let(:persistence_engine) { mock(:persistence_engine) }
    let(:event_store) { mock(:event_store, :persistence_engine => persistence_engine)}
    let(:event11) { mock(:event11) }
    let(:event12) { mock(:event12) }
    let(:event21) { mock(:event21) }
    let(:event22) { mock(:event22) }
    let(:all_events) { [event11, event12, event21, event22]}
    
    before(:each) do
      rm1.stub(:setup => nil, :cleanup! => nil, :rebuild_required? => false, :setup_required? => false, :can_handle_message? => false)
      rm2.stub(:setup => nil, :cleanup! => nil, :rebuild_required? => false, :setup_required? => false, :can_handle_message? => false)
      rm3.stub(:setup => nil, :cleanup! => nil, :rebuild_required? => false, :setup_required? => false, :can_handle_message? => false)

      subject.stub(:event_store) { event_store }
      persistence_engine.should_receive(:for_each_commit) do |&block|
        block.call mock(:commit1, :events => [mock(:event, :body => event11), mock(:event, :body => event12)])
        block.call mock(:commit2, :events => [mock(:event, :body => event21), mock(:event, :body => event22)])
      end
      register_rmx
    end
    
    it "should not publish events if read models needs rebuild" do
      persistence_engine.rspec_reset
      persistence_engine.should_not_receive(:for_each_commit)
      subject.initialize_read_models cleanup_all: false
    end
    
    context ":cleanup_all => false" do
      it "should cleanup and setup read models that needs rebuild" do
        rm1.should_receive(:rebuild_required?) { true }
        rm3.should_receive(:rebuild_required?) { true }
        rm1.should_receive(:cleanup!)
        rm3.should_receive(:cleanup!)
        rm1.should_receive(:setup)
        rm3.should_receive(:setup)
        subject.initialize_read_models cleanup_all: false
      end
      
      it "should dispatch events to all read models that has been rebuilt" do
        rm1.should_receive(:rebuild_required?) { true }
        rm3.should_receive(:rebuild_required?) { true }
        all_events.each { |e| 
          rm1.should_receive(:can_handle_message?).with(e).and_return(true)
          rm1.should_receive(:handle_message).with(e).and_return(true)
          rm3.should_receive(:can_handle_message?).with(e).and_return(true)
          rm3.should_receive(:handle_message).with(e).and_return(true)
        }
        
        subject.initialize_read_models cleanup_all: false
      end
      
      it "should setup all read models that needs setup" do
        rm1.should_receive(:setup_required?) { true }
        rm3.should_receive(:setup_required?) { true }
        rm1.should_receive(:setup)
        rm3.should_receive(:setup)
        subject.initialize_read_models cleanup_all: false
      end
      
      it "should dispatch events to all read models that has been setup" do
        rm1.should_receive(:setup_required?) { true }
        rm3.should_receive(:setup_required?) { true }

        all_events.each { |e| 
          rm1.should_receive(:can_handle_message?).with(e).and_return(true)
          rm1.should_receive(:handle_message).with(e).and_return(true)
          rm3.should_receive(:can_handle_message?).with(e).and_return(true)
          rm3.should_receive(:handle_message).with(e).and_return(true)
        }
        
        subject.initialize_read_models cleanup_all: false
      end
    end
    
    context ":cleanup_all => true" do
      it "should cleanup and setup all read models" do
        rm1.should_receive(:cleanup!)
        rm2.should_receive(:cleanup!)
        rm3.should_receive(:cleanup!)
        rm1.should_receive(:setup)
        rm2.should_receive(:setup)
        rm3.should_receive(:setup)
        subject.initialize_read_models cleanup_all: true
      end
      
      it "should dispatch events to all read models" do
        all_events.each { |e| 
          rm1.should_receive(:can_handle_message?).with(e).and_return(true)
          rm1.should_receive(:handle_message).with(e).and_return(true)
          rm2.should_receive(:can_handle_message?).with(e).and_return(true)
          rm2.should_receive(:handle_message).with(e).and_return(true)
          rm3.should_receive(:can_handle_message?).with(e).and_return(true)
          rm3.should_receive(:handle_message).with(e).and_return(true)
        }
        subject.initialize_read_models cleanup_all: true
      end
    end
  end
  
  describe "with_dispatch_undispatched_commits" do
    it "should dispatch_undispatched" do
      event_store = mock(:event_store)
      subject.stub(:event_store) {event_store}
      event_store.should_receive(:dispatch_undispatched)
      subject.with_dispatch_undispatched_commits
    end
  end
end