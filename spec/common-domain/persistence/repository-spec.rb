require 'spec-helper'

describe CommonDomain::Persistence::Repository do
  let(:builder) { CommonDomain::Persistence::AggregatesBuilder.new }
  let(:stream) { event_store.create_stream('aggregate-1') }
  let(:event_store) {
    store = EventStore.bootstrap do |with|
      with.log4r_logging
      with.in_memory_persistence
    end
    store
  }
  let(:aggregate_class) { Class.new(CommonDomain::Aggregate) do
    def raise_event(*args) super; end
    on(String) { |evt|  }
  end }
  let(:aggregate) { aggregate_class.new('aggregate-1') }
  let(:s) { CommonDomain::Persistence::Snapshots }
  subject { described_class.new event_store, builder }
  
  describe "exists?" do
    it "should return true if stream exists" do
      expect(event_store).to receive(:stream_exists?).with('aggregate-320').and_return(true)
      expect(subject.exists?('aggregate-320')).to be_truthy
    end
  end
  
  describe "get_by_id" do
    before(:each) do
      allow(builder).to receive(:build) { aggregate }
    end
    
    it "should use builder to construct new aggregate instance" do
      expect(builder).to receive(:build).with(aggregate_class, "aggregate-1").and_return(aggregate)
      stream.add 'msg-1'
      stream.commit_changes
      expect(subject.get_by_id(aggregate_class, "aggregate-1")).to eql aggregate
    end
    
    it "should use event store to obtain event stream and apply all events from it" do      
      event1 = double(:event1)
      event2 = double(:event1)
      stream.add(event1).add(event2).commit_changes
            
      expect(aggregate).to receive(:apply_event).with(event1)
      expect(aggregate).to receive(:apply_event).with(event2)
      expect(subject.get_by_id(aggregate_class, "aggregate-1")).to eql aggregate
    end
    
    it 'should cache the stream for subsequent calls on the same repo' do
      event1 = double(:event1)
      event2 = double(:event1)
      stream.add(event1).add(event2).commit_changes
      allow(aggregate).to receive(:apply_event)
      expect(event_store).to receive(:open_stream).with('aggregate-1').and_return(stream).once
      expect(subject.get_by_id(aggregate_class, 'aggregate-1')).to eql aggregate
      expect(subject.get_by_id(aggregate_class, 'aggregate-1')).to eql aggregate
    end
    
    it 'should raise aggregate not found error if trying to get not existing aggregate' do            
      expect(lambda { subject.get_by_id(aggregate_class, 'aggregate-2') }).to raise_error(CommonDomain::Persistence::AggregateNotFoundError)
    end
    
    describe 'snapshots' do
      let(:snapshots_repo) { instance_double(CommonDomain::Persistence::Snapshots::SnapshotsRepository, get: nil, add: nil)}
      
      it 'should reconstruct the aggregate from snapshot if available' do
        snapshot = s::Snapshot.new('aggregate-1', 10, 'snapshot-data')
        expect(snapshots_repo).to receive(:get).with('aggregate-1') { snapshot }
        expect(builder).to receive(:build).with(aggregate_class, snapshot) { aggregate }
        
        event1 = double(:event1)
        event2 = double(:event1)
        
        expect(event_store).to receive(:stream_exists?).with('aggregate-1') { true }
        expect(event_store).to receive(:open_stream).with('aggregate-1', min_revision: snapshot.version + 1).and_return(stream)
        expect(stream).to receive(:committed_events).and_return [event1, event2]
        expect(aggregate).to receive(:apply_event).with(event1)
        expect(aggregate).to receive(:apply_event).with(event2)
        
        repository = described_class.new event_store, builder, snapshots_repo
        actual_aggregate = repository.get_by_id aggregate_class, 'aggregate-1'
        expect(actual_aggregate).to be aggregate
      end
      
      it 'should cache the snapshot for subsequent calls' do
        snapshot = s::Snapshot.new('aggregate-1', 10, 'snapshot-data')
        expect(snapshots_repo).to receive(:get).with('aggregate-1').and_return(snapshot).once
        allow(builder).to receive(:build) { aggregate }
        
        event1 = double(:event1)
        event2 = double(:event1)
        
        expect(event_store).to receive(:stream_exists?) { true }
        expect(event_store).to receive(:open_stream).with('aggregate-1', min_revision: snapshot.version + 1).and_return(stream).once
        allow(stream).to receive(:committed_events).and_return [event1, event2]
        allow(aggregate).to receive(:apply_event)
        
        repository = described_class.new event_store, builder, snapshots_repo
        actual_aggregate = repository.get_by_id aggregate_class, 'aggregate-1'
        expect(actual_aggregate).to be aggregate
        actual_aggregate = repository.get_by_id aggregate_class, 'aggregate-1'
        expect(actual_aggregate).to be aggregate
      end
    end
  end
  
  describe 'save' do
    before(:each) do
      stream.add('initial-evt-1').commit_changes
      aggregate.raise_event 'evt-1'
      allow(event_store).to receive(:open_stream).with(stream.stream_id) { stream }
    end
    
    it "should return the aggregate" do
      expect(subject.save(aggregate)).to be aggregate
      aggregate.raise_event 'evt-2'
      expect(subject.save(aggregate)).to be aggregate
    end

    it 'should create new stream for new aggregate' do
      aggregate.clear_uncommitted_events
      expect(event_store).to receive(:create_stream).with(stream.stream_id) { stream }
      evt1, evt2, evt3 = 'evt1', 'evt2', 'evt3'
      aggregate.raise_event evt1
      aggregate.raise_event evt2
      aggregate.raise_event evt3
      
      expect(stream).to receive(:add).with(evt1)
      expect(stream).to receive(:add).with(evt2)
      expect(stream).to receive(:add).with(evt3)
      expect(stream).to receive(:commit_changes).with({})
      expect(aggregate).to receive(:clear_uncommitted_events)
      subject.save(aggregate)
    end
    
    it 'should use open stream and flush all the events into it' do
      expect(event_store).to receive(:open_stream).and_return(stream).once
      expect(event_store).not_to receive(:create_stream)
      
      evt1, evt2, evt3 = 'evt1', 'evt2', 'evt3'
      aggregate = subject.get_by_id aggregate_class, 'aggregate-1'
      aggregate.raise_event evt1
      aggregate.raise_event evt2
      aggregate.raise_event evt3

      expect(stream).to receive(:add).with(evt1)
      expect(stream).to receive(:add).with(evt2)
      expect(stream).to receive(:add).with(evt3)
      expect(stream).to receive(:commit_changes).with({})
      expect(aggregate).to receive(:clear_uncommitted_events)
      subject.save(aggregate)
    end
    
    it 'should commit stream with headers' do
      allow(builder).to receive(:build).and_return(aggregate)
      subject.get_by_id(aggregate_class, 'aggregate-1')
      aggregate.raise_event 'evt3'
      headers = {header: 'header-1'}
      expect(stream).to receive(:commit_changes).with(headers)
      subject.save(aggregate, headers)
    end
    
    it 'should do nothing if aggregate has no changes' do
      aggregate.clear_uncommitted_events
      expect(event_store).not_to receive(:create_stream)
      subject.save(aggregate)
    end
    
    describe 'snapshots' do
      let(:snapshots_repo) { instance_double(CommonDomain::Persistence::Snapshots::SnapshotsRepository) }

      before do
        allow(event_store).to receive(:create_stream) { stream }
      end
      
      it 'should add a snapshot if needed' do
        snapshot_data = double(:snapshot_data)
        aggregate.raise_event 'evt-1'
        expect(stream).to receive(:stream_revision).at_least(1).times { 233 }
        subject = described_class.new event_store, builder, snapshots_repo
        expect(aggregate_class).to receive(:add_snapshot?).with(aggregate) { true }
        expect(aggregate).to receive(:get_snapshot) { snapshot_data }
        expect(snapshots_repo).to receive(:add).with(s::Snapshot.new('aggregate-1', 233, snapshot_data))
        subject.save(aggregate)
      end
    end
  end
end