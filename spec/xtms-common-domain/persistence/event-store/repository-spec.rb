require 'spec-helper'

describe CommonDomain::Persistence::EventStore::Repository do
  let(:builder) { double(:aggregate_builder) }
  let(:event_stream) { double(:event_stream, new_stream?: false, :committed_events => []) }
  let(:event_store) { double(:event_store, :open_stream => event_stream) }
  let(:aggregate) { double("aggregate", :aggregate_id => "aggregate-1") }
  
  subject { described_class.new event_store, builder }
  
  describe "exists?" do
    it "should return true if stream exists" do
      expect(event_store).to receive(:stream_exists?).with('aggregate-320').and_return(true)
      expect(subject.exists?('aggregate-320')).to be_truthy
    end
  end
  
  describe "get_by_id" do
    let(:aggregate_class) { double("aggregate-class") }
    
    before(:each) do
      allow(builder).to receive(:build) { aggregate }
    end
    
    it "should use builder to construct new aggregate instance" do
      expect(builder).to receive(:build).with(aggregate_class, "aggregate-1").and_return(aggregate)
      expect(subject.get_by_id(aggregate_class, "aggregate-1")).to eql aggregate
    end
    
    it "should use event store to obtain event stream and apply all events from it" do
      event1 = double(:event1, :body => double(:body1))
      event2 = double(:event1, :body => double(:body2))
      expect(event_store).to receive(:open_stream).with('aggregate-1').and_return(event_stream)
      expect(event_stream).to receive(:committed_events).and_return [event1, event2]
      expect(aggregate).to receive(:apply_event).with(event1.body)
      expect(aggregate).to receive(:apply_event).with(event2.body)
      expect(subject.get_by_id(aggregate_class, "aggregate-1")).to eql aggregate
    end
    
    it "should raise aggregate not found error if trying to get not existing aggregate" do
      expect(event_stream).to receive(:new_stream?).and_return(true)
      expect(event_store).to receive(:open_stream).with('aggregate-1').and_return(event_stream)
      expect(lambda { subject.get_by_id(aggregate_class, "aggregate-1") }).to raise_error(CommonDomain::Persistence::AggregateNotFoundError)
    end
  end
  
  describe "save" do
    let(:stream) { double(:stream) }
    it "should use stream-io to flush aggregate changes" do
      expect(subject).to be_a_kind_of(CommonDomain::Persistence::EventStore::StreamIO)
      expect(subject).to receive(:flush_changes).with(aggregate, event_store).and_return(aggregate)
      expect(subject.save(aggregate)).to be aggregate
    end
    
    it "should commit stream on yield" do
      expect(subject).to receive(:flush_changes) do |aggregate, opener, &block|
        expect(stream).to receive(:commit_changes)
        block.call(stream)
      end
      subject.save(aggregate)
    end
    
    it "should commit stream with headers" do
      headers = {header: 'header-1'}
      expect(stream).to receive(:commit_changes).with(headers)
      allow(subject).to receive(:flush_changes) do |aggregate, opener, &block|
        block.call(stream)
      end
      subject.save(aggregate, headers)
    end
  end
  
  describe "create_work" do
    it "should create and return an instance of EventStore::Work" do
      work = double(:work)
      expect(CommonDomain::Persistence::EventStore::Work).to receive(:new).with(event_store, builder).and_return(work)
      expect(subject.send(:create_work)).to be work
    end
  end
end