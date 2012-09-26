require 'spec-helper'

describe CommonDomain::Persistence::EventStoreRepository do
  let(:builder) { mock(:aggregate_builder) }
  let(:event_stream) { mock(:event_stream, :committed_events => []) }
  let(:event_store) { mock(:event_store, :open_stream => event_stream) }
  let(:aggregate) { mock("aggregate", :aggregate_id => "aggregate-1") }
  
  subject { described_class.new event_store, builder }
  
  describe "get_by_id" do
    let(:aggregate_class) { mock("aggregate-class") }
    
    before(:each) do
      builder.stub(:build) { aggregate }
    end
    
    it "should use builder to construct new aggregate instance" do
      builder.should_receive(:build).with(aggregate_class, "aggregate-1").and_return(aggregate)
      subject.get_by_id(aggregate_class, "aggregate-1").should eql aggregate
    end
    
    it "should use event store to obtain event stream and apply all events from it" do
      event1 = mock(:event1, :body => mock(:body1))
      event2 = mock(:event1, :body => mock(:body2))
      event_store.should_receive(:open_stream).with('aggregate-1').and_return(event_stream)
      event_stream.should_receive(:committed_events).and_return [event1, event2]
      aggregate.should_receive(:apply_event).with(event1.body)
      aggregate.should_receive(:apply_event).with(event2.body)
      subject.get_by_id(aggregate_class, "aggregate-1").should eql aggregate
    end
  end
  
  describe "save" do
    before(:each) do
      aggregate.stub(:get_uncommitted_events => [], :clear_uncommitted_events => nil)
    end
    
    it "should commit all uncommitted events into the event store and clear uncommitted events then" do
      evt1 = mock(:event1)
      evt2 = mock(:event1)
      headers = { header1: "header-1", header2: "header-2" }
      aggregate.should_receive(:get_uncommitted_events).and_return([evt1, evt2])
      event_store.should_receive(:open_stream).with("aggregate-1").and_return(event_stream)
      event_stream.should_receive(:add).with(EventStore::EventMessage.new evt1)
      event_stream.should_receive(:add).with(EventStore::EventMessage.new evt2)
      event_stream.should_receive(:commit_changes).with(headers)
      aggregate.should_receive(:clear_uncommitted_events)
      
      subject.save(aggregate, headers).should eql aggregate
    end
  end
end