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
    
    describe 'snapshots' do
      let(:snapshots_repo) { double(:snapshots_repository, get: nil, add: nil)}
      let(:s) { CommonDomain::Persistence::Snapshots }
      
      it 'should reconstruct the aggregate from snapshot if available' do
        snapshot = s::Snapshot.new('aggregate-1', 10, 'snapshot-data')
        expect(snapshots_repo).to receive(:get).with('aggregate-1') { snapshot }
        expect(builder).to receive(:build).with(aggregate_class, snapshot) { aggregate }
        
        event1 = double(:event1, :body => double(:body1))
        event2 = double(:event1, :body => double(:body2))
        
        expect(event_store).to receive(:open_stream).with('aggregate-1', min_revision: snapshot.version + 1).and_return(event_stream)
        expect(event_stream).to receive(:committed_events).and_return [event1, event2]
        expect(aggregate).to receive(:apply_event).with(event1.body)
        expect(aggregate).to receive(:apply_event).with(event2.body)
        
        repository = described_class.new event_store, builder, snapshots_repo
        actual_aggregate = repository.get_by_id aggregate_class, 'aggregate-1'
      end
    end
  end
  
  describe "save" do
    let(:stream) { double(:stream) }
    
    before(:each) do
      allow(event_store).to receive(:open_stream) { stream }
      allow(stream).to receive(:add)
      allow(stream).to receive(:commit_changes)
      allow(aggregate).to receive(:get_uncommitted_events) { [] }
      allow(aggregate).to receive(:clear_uncommitted_events)
    end
    
    it "should return the aggregate" do
      expect(subject.save(aggregate)).to be aggregate
    end
    
    it "should get the stream, flush all the events into the stream and clear the aggregate" do
      evt1, evt2, evt3 = double(:evt1), double(:evt2), double(:evt3)
      expect(aggregate).to receive(:get_uncommitted_events).and_return([evt1, evt2, evt3])
      expect(stream).to receive(:add).with(EventStore::EventMessage.new evt1)
      expect(stream).to receive(:add).with(EventStore::EventMessage.new evt2)
      expect(stream).to receive(:add).with(EventStore::EventMessage.new evt3)
      expect(stream).to receive(:commit_changes)
      expect(aggregate).to receive(:clear_uncommitted_events)
      subject.save(aggregate)
    end
    
    it "should commit stream with headers" do
      headers = {header: 'header-1'}
      expect(stream).to receive(:commit_changes).with(headers)
      subject.save(aggregate, headers)
    end
  end
end