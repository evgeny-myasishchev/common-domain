require 'spec-helper'

describe CommonDomain::Persistence::EventStore::Repository do
  let(:builder) { double(:aggregate_builder) }
  let(:event_stream) { double(:event_stream, new_stream?: false, :committed_events => []) }
  let(:event_store) { double(:event_store, :open_stream => event_stream) }
  let(:aggregate) { double("aggregate", :aggregate_id => "aggregate-1") }
  
  subject { described_class.new event_store, builder }
  
  describe "exists?" do
    it "should return true if stream exists" do
      event_store.should_receive(:stream_exists?).with('aggregate-320').and_return(true)
      subject.exists?('aggregate-320').should be_true
    end
  end
  
  describe "get_by_id" do
    let(:aggregate_class) { double("aggregate-class") }
    
    before(:each) do
      builder.stub(:build) { aggregate }
    end
    
    it "should use builder to construct new aggregate instance" do
      builder.should_receive(:build).with(aggregate_class, "aggregate-1").and_return(aggregate)
      subject.get_by_id(aggregate_class, "aggregate-1").should eql aggregate
    end
    
    it "should use event store to obtain event stream and apply all events from it" do
      event1 = double(:event1, :body => double(:body1))
      event2 = double(:event1, :body => double(:body2))
      event_store.should_receive(:open_stream).with('aggregate-1').and_return(event_stream)
      event_stream.should_receive(:committed_events).and_return [event1, event2]
      aggregate.should_receive(:apply_event).with(event1.body)
      aggregate.should_receive(:apply_event).with(event2.body)
      subject.get_by_id(aggregate_class, "aggregate-1").should eql aggregate
    end
    
    it "should raise aggregate not found error if trying to get not existing aggregate" do
      event_stream.should_receive(:new_stream?).and_return(true)
      event_store.should_receive(:open_stream).with('aggregate-1').and_return(event_stream)
      lambda { subject.get_by_id(aggregate_class, "aggregate-1") }.should raise_error(CommonDomain::Persistence::AggregateNotFoundError)
    end
  end
  
  describe "save" do
    let(:stream) { double(:stream) }
    it "should use stream-io to flush aggregate changes" do
      subject.should be_a_kind_of(CommonDomain::Persistence::EventStore::StreamIO)
      subject.should_receive(:flush_changes).with(aggregate, event_store).and_return(aggregate)
      subject.save(aggregate).should be aggregate
    end
    
    it "should commit stream on yield" do
      subject.should_receive(:flush_changes) do |aggregate, opener, &block|
        stream.should_receive(:commit_changes)
        block.call(stream)
      end
      subject.save(aggregate)
    end
    
    it "should commit stream with headers" do
      headers = {header: 'header-1'}
      stream.should_receive(:commit_changes).with(headers)
      subject.stub(:flush_changes) do |aggregate, opener, &block|
        block.call(stream)
      end
      subject.save(aggregate, headers)
    end
  end
  
  describe "create_work" do
    it "should create and return an instance of EventStore::Work" do
      work = double(:work)
      CommonDomain::Persistence::EventStore::Work.should_receive(:new).with(event_store, builder).and_return(work)
      subject.send(:create_work).should be work
    end
  end
end