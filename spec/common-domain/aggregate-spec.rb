require 'spec-helper'

describe CommonDomain::Aggregate do
  subject { described_class.new "account-1" }
  
  describe 'initializer' do
    it 'should initialize the aggregate with given id' do
      expect(subject.aggregate_id).to eql 'account-1'
    end
    
    it 'should initialize the aggregate with snapshot' do
      aggregate_class = Class.new(described_class) do
        attr_reader :applied_snapshot
        def apply_snapshot(data)
          @applied_snapshot = data
        end
      end
      snapshot = CommonDomain::Persistence::Snapshots::Snapshot.new 'account-from-snapshot-1', 223, 'snapshot-data'
      subject = aggregate_class.new snapshot
      expect(subject.aggregate_id).to eql 'account-from-snapshot-1'
      expect(subject.version).to eql 223
      expect(subject.applied_snapshot).to eql 'snapshot-data'
    end
  end
  
  describe "apply_event" do
    before(:each) do
      allow(subject).to receive(:handle_message)
    end
    
    it "should process events" do
      event1 = double(:event1)
      event2 = double(:event2)
      
      expect(subject).to receive(:handle_message).with(event1)
      expect(subject).to receive(:handle_message).with(event2)
      
      subject.apply_event event1
      subject.apply_event event2
    end
    
    it "should set aggregate version to event version" do
      event1 = double(:event1)
      event2 = double(:event2)
      
      subject.apply_event event1
      expect(subject.version).to eql 1
      subject.apply_event event2
      expect(subject.version).to eql 2
    end
    
    it 'should increment applied_events_number number' do
      subject.apply_event double(:event1)
      expect(subject.applied_events_number).to eql 1
      subject.apply_event double(:event1)
      expect(subject.applied_events_number).to eql 2
      subject.apply_event double(:event1)
      expect(subject.applied_events_number).to eql 3
    end
    
    it 'should increment version' do
      subject.apply_event double(:event1)
      expect(subject.version).to eql 1
      subject.apply_event double(:event1)
      expect(subject.version).to eql 2
      subject.apply_event double(:event1)
      expect(subject.version).to eql 3
    end
    
    it "should return self" do
      expect(subject.apply_event(double(:event1))).to be subject
    end
  end
  
  describe "raise_event" do
    it "should apply event" do
      account_opened  = double(:account_opened)
      expect(subject).to receive(:apply_event).with(account_opened)
      subject.send(:raise_event, account_opened)
    end
    
    it "should return self" do
      allow(subject).to receive(:apply_event)
      expect(subject.send(:raise_event, double(:account_opened))).to be subject
    end
    
    it "should add an event to uncommitted events" do
      account_opened  = double(:account_opened)
      account_renamed = double(:account_renamed)
      allow(subject).to receive(:apply_event)
      subject.send(:raise_event, account_opened)
      subject.send(:raise_event, account_renamed)
      
      expect(subject.get_uncommitted_events.length).to eql(2)
      expect(subject.get_uncommitted_events[0]).to be account_opened
      expect(subject.get_uncommitted_events[1]).to be account_renamed
    end
  end
  
  describe "clear_uncommitted_events" do
    it "should empty uncommitted events" do
      account_opened  = double(:account_opened)
      account_renamed = double(:account_renamed)
      allow(subject).to receive(:apply_event)
      subject.send(:raise_event, account_opened)
      subject.send(:raise_event, account_renamed)
      
      subject.clear_uncommitted_events
      expect(subject.get_uncommitted_events).to be_empty
    end
  end
end
