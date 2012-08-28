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
  
  def register_rmx
    subject.with_read_models do |read_models|
      read_models.register :rm1, rm1
      read_models.register :rm2, rm2
    end
  end
  
  describe "rebuild_read_models" do
    let(:persistence_engine) { mock(:persistence_engine) }
    let(:event_store) { mock(:event_store, :persistence_engine => persistence_engine)}
    let(:event11) { mock(:event11) }
    let(:event12) { mock(:event12) }
    let(:event21) { mock(:event21) }
    let(:event22) { mock(:event22) }
    let(:all_events) { [event11, event12, event21, event22]}
    
    before(:each) do
      subject.stub(:event_store) { event_store }
      persistence_engine.should_receive(:for_each_commit) do |&block|
        block.call mock(:commit1, :events => [mock(:event, :body => event11), mock(:event, :body => event12)])
        block.call mock(:commit2, :events => [mock(:event, :body => event21), mock(:event, :body => event22)])
      end
      register_rmx
    end
    
    it "should rebuild read models with all events" do
      rm1.should_receive(:purge!)
      rm2.should_receive(:purge!)
      all_events.each { |e| 
        rm1.should_receive(:can_handle_message?).with(e).and_return(true)
        rm1.should_receive(:handle_message).with(e).and_return(true)
        rm2.should_receive(:can_handle_message?).with(e).and_return(true)
        rm2.should_receive(:handle_message).with(e).and_return(true)
      }
      subject.rebuild_read_models
    end
    
    context "required only" do
      it "should rebuild required only read models" do
        rm1.should_receive(:rebuild_required?) { false }
        rm2.should_receive(:rebuild_required?) { true }
        rm2.should_receive(:purge!)
        all_events.each { |e|
          rm2.should_receive(:can_handle_message?).with(e).and_return(true)
          rm2.should_receive(:handle_message).with(e).and_return(true)
        }
        subject.rebuild_read_models :required_only => true
      end
      
      it "should not publish all events if no read models needs rebuild" do
        persistence_engine.rspec_reset
        rm1.should_receive(:rebuild_required?) { false }
        rm2.should_receive(:rebuild_required?) { false }
        subject.rebuild_read_models :required_only => true
      end
    end
  end
  
  describe "bootstrap_read_models" do
    it "should setup each read model" do
      rm1.should_receive(:setup)
      rm2.should_receive(:setup)
      register_rmx
    end
  end
end