require 'spec-helper'

describe CommonDomain::Persistence::EventStore::Work do
  let(:event_store_work) { double(:event_store_work) }
  let(:event_store) { double(:event_store, begin_work: event_store_work) }
  let(:repository) { double(:event_store_repository) }
  let(:builder) { double(:builder) }
  
  before(:each) do
    allow(CommonDomain::Persistence::EventStore::Repository).to receive(:new) { repository }
  end
  
  subject { described_class.new event_store, builder }
  
  describe "initialize" do
    it "should use event_store to begin new event store work and create event store repository with it" do
      expect(event_store).to receive(:begin_work).and_return(event_store_work)
      expect(CommonDomain::Persistence::EventStore::Repository).to receive(:new).
        with(event_store_work, builder).and_return(repository)
      subject = described_class.new event_store, builder
      expect(subject.repository).to be repository
    end
  end
  
  describe "exists?" do
    before(:each) do
      allow(repository).to receive(:exists?) { false }
    end
    
    it "should return true the aggregate exists in the repository" do
      expect(repository).to receive(:exists?).with('aggregate-392').and_return(true)
      expect(subject.exists?('aggregate-392')).to be_truthy
    end
    
    it "should return true if the aggregate added as a new" do
      aggregate = double(:aggregate, aggregate_id: 'aggregate-392')
      subject.add_new aggregate
      expect(subject.exists?('aggregate-392')).to be_truthy
    end
    
    it "should return false if the aggregate does not eixst" do
      expect(subject.exists?('aggregate-392')).to be_falsey
    end
  end
  
  describe "get_by_id" do
    let(:aggregate) { double(:aggregate) }
    let(:aggregate_class) { double(:aggregate_class) }
    
    it "should use repository to get the aggregate" do
      expect(repository).to receive(:get_by_id).with(aggregate_class, 'aggregate-8820').and_return(aggregate)
      expect(subject.get_by_id(aggregate_class, 'aggregate-8820')).to be aggregate
    end
    
    it "should return same instance of the aggregate without accessing the repo" do
      expect(repository).to receive(:get_by_id).once.and_return(aggregate)
      expect(subject.get_by_id(aggregate_class, 'aggregate-8820')).to be aggregate
      expect(subject.get_by_id(aggregate_class, 'aggregate-8820')).to be aggregate
    end
  end
  
  describe "add_new" do
    let(:aggregate) { double(:aggregate, aggregate_id: 'aggregate-77893') }
    before(:each) do
      allow(event_store_work).to receive(:commit_changes)
    end
    
    it "should add an aggregate to internal structures so it's flushed on commit_changes" do
      subject.add_new aggregate
      expect(subject).to receive(:flush_changes).with(aggregate, event_store_work)
      subject.commit_changes
    end
    
    it "should raise error if aggregate_id not assigned yet" do
      allow(aggregate).to receive(:aggregate_id) { nil }
      expect(lambda { subject.add_new aggregate }).to raise_error("Can not add new aggregate because aggregate_id is not assigned yet.")
      expect(subject).not_to receive(:flush_changes)
      subject.commit_changes
    end
    
    it "should raise error if aggregate_id already added" do
      subject.add_new aggregate
      expect(lambda { subject.add_new aggregate }).to raise_error("Another aggregate with id 'aggregate-77893' already added.")
      expect(subject).to receive(:flush_changes).once.with(aggregate, event_store_work)
      subject.commit_changes
    end
    
    it "should add an aggregate to the same structure so it's returned by geb_by_id" do
      subject.add_new aggregate
      expect(repository).not_to receive(:get_by_id)
      expect(subject.get_by_id(nil, 'aggregate-77893')).to be aggregate
    end
    
    it "should return the aggregate" do
      expect(subject.add_new(aggregate)).to be aggregate
    end
  end
  
  describe "commit_changes" do
    let(:aggregate_1) { double(:aggregate_1) }
    let(:aggregate_2) { double(:aggregate_2) }
    before(:each) do
      allow(repository).to receive(:get_by_id).with(anything, 'aggregate-1').and_return(aggregate_1)
      allow(repository).to receive(:get_by_id).with(anything, 'aggregate-2').and_return(aggregate_2)
      subject.get_by_id(nil, 'aggregate-1')
      subject.get_by_id(nil, 'aggregate-2')
      allow(subject).to receive(:flush_changes)
      allow(event_store_work).to receive(:commit_changes)
    end
    
    it "should use stream-io to flush changes of all retrieved aggregates and then commit the work of event store" do
      expect(subject).to be_a_kind_of(CommonDomain::Persistence::EventStore::StreamIO)
      expect(subject).to receive(:flush_changes).with(aggregate_1, event_store_work)
      expect(subject).to receive(:flush_changes).with(aggregate_2, event_store_work)
      expect(event_store_work).to receive(:commit_changes)
      subject.commit_changes
    end
    
    it "should commit changes of event store work with headers" do
      headers = {header1: 'header-1'}
      expect(event_store_work).to receive(:commit_changes).with(headers)
      subject.commit_changes headers
    end
    
    it "should return nil" do
      expect(subject.commit_changes).to be_nil
    end
    
    it "should notify when committed" do
      expect(subject).to receive(:notify_on_committed)
      subject.commit_changes
    end
  end
end