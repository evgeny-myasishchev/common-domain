require 'spec-helper'

describe CommonDomain::Persistence::EventStoreRepository::EventStoreWork do
  let(:event_store_work) { mock(:event_store_work) }
  let(:event_store) { mock(:event_store, begin_work: event_store_work) }
  let(:repository) { mock(:event_store_repository) }
  let(:builder) { mock(:builder) }
  
  before(:each) do
    CommonDomain::Persistence::EventStoreRepository.stub(:new) { repository }
  end
  
  subject { described_class.new event_store, builder }
  
  describe "initialize" do
    it "should use event_store to begin new event store work and create event store repository with it" do
      event_store.should_receive(:begin_work).and_return(event_store_work)
      CommonDomain::Persistence::EventStoreRepository.should_receive(:new).
        with(event_store_work, builder).and_return(repository)
      subject = described_class.new event_store, builder
      subject.repository.should be repository
    end
  end
  
  describe "get_by_id" do
    let(:aggregate) { mock(:aggregate) }
    let(:aggregate_class) { mock(:aggregate_class) }
    
    it "should use repository to get the aggregate" do
      repository.should_receive(:get_by_id).with(aggregate_class, 'aggregate-8820').and_return(aggregate)
      subject.get_by_id(aggregate_class, 'aggregate-8820').should be aggregate
    end
    
    it "should return same instance of the aggregate without accessing the repo" do
      repository.should_receive(:get_by_id).once.and_return(aggregate)
      subject.get_by_id(aggregate_class, 'aggregate-8820').should be aggregate
      subject.get_by_id(aggregate_class, 'aggregate-8820').should be aggregate
    end
  end
  
  describe "add_new" do
    let(:aggregate) { mock(:aggregate, aggregate_id: 'aggregate-77893') }
    before(:each) do
      event_store_work.stub(:commit_changes)
    end
    
    it "should add an aggregate to internal structures so it's saved on commit_changes" do
      subject.add_new aggregate
      repository.should_receive(:save).with(aggregate)
      subject.commit_changes
    end
    
    it "should raise error if aggregate_id not assigned yet" do
      aggregate.stub(:aggregate_id) { nil }
      lambda { subject.add_new aggregate }.should raise_error("Can not add new aggregate because aggregate_id is not assigned yet.")
      repository.should_not_receive(:save)
      subject.commit_changes
    end
    
    it "should raise error if aggregate_id already added" do
      subject.add_new aggregate
      lambda { subject.add_new aggregate }.should raise_error("Another aggregate with id 'aggregate-77893' already added.")
      repository.should_receive(:save).once.with(aggregate)
      subject.commit_changes
    end
    
    it "should add an aggregate to the same structure so it's returned by geb_by_id" do
      subject.add_new aggregate
      repository.should_not_receive(:get_by_id)
      subject.get_by_id(nil, 'aggregate-77893').should be aggregate
    end
  end
  
  describe "commit_changes" do
    let(:aggregate_1) { mock(:aggregate_1) }
    let(:aggregate_2) { mock(:aggregate_2) }
    before(:each) do
      repository.stub(:get_by_id).with(anything, 'aggregate-1').and_return(aggregate_1)
      repository.stub(:get_by_id).with(anything, 'aggregate-2').and_return(aggregate_2)
      subject.get_by_id(nil, 'aggregate-1')
      subject.get_by_id(nil, 'aggregate-2')
      
      repository.stub(:save)
      event_store_work.stub(:commit_changes)
    end
    
    it "should use repository to commit changes of all retrieved aggregates and then commit the work of event store" do
      repository.should_receive(:save).with(aggregate_1)
      repository.should_receive(:save).with(aggregate_2)
      event_store_work.should_receive(:commit_changes)
      subject.commit_changes
    end
    
    it "should commit changes of event store work with headers" do
      headers = {header1: 'header-1'}
      event_store_work.should_receive(:commit_changes).with(headers)
      subject.commit_changes headers
    end
    
    it "should return nil" do
      subject.commit_changes.should be_nil
    end
  end
end