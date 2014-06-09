require 'spec-helper'

describe CommonDomain::Aggregate do
  subject { described_class.new "account-1" }
  describe "apply_event" do
    it "should process events" do
      event1 = double(:event1, :version => 1)
      event2 = double(:event2, :version => 2)
      
      expect(subject).to receive(:handle_message).with(event1)
      expect(subject).to receive(:handle_message).with(event2)
      
      subject.apply_event event1
      subject.apply_event event2
    end
    
    it "should set aggregate version to event version" do
      event1 = double(:event1, :version => 1)
      event2 = double(:event2, :version => 2)
      
      allow(subject).to receive(:handle_message)
      
      subject.apply_event event1
      expect(subject.version).to eql 1
      subject.apply_event event2
      expect(subject.version).to eql 2
    end
    
    it "should return self" do
      allow(subject).to receive(:handle_message)
      expect(subject.apply_event(double(:event1, :version => 1))).to be subject
    end
  end
  
  describe "raise_event" do
    it "should set event version to aggregate version + 1" do
      account_opened  = double(:account_opened)
      allow(subject).to receive(:apply_event)
      allow(subject).to receive(:version) { 10 }
      expect(account_opened).to receive(:version=).with(11)
      subject.send(:raise_event, account_opened)
    end
    
    it "should apply event" do
      account_opened  = double(:account_opened, :version= => nil)
      expect(subject).to receive(:apply_event).with(account_opened)
      subject.send(:raise_event, account_opened)
    end
    
    it "should return self" do
      allow(subject).to receive(:apply_event)
      expect(subject.send(:raise_event, double(:account_opened, :version= => nil))).to be subject
    end
    
    it "should add an event to uncommitted events" do
      account_opened  = double(:account_opened, :version= => nil)
      account_renamed = double(:account_renamed, :version= => nil)
      allow(subject).to receive(:apply_event)
      subject.send(:raise_event, account_opened)
      subject.send(:raise_event, account_renamed)
      
      expect(subject.get_uncommitted_events.length).to eql(2)
      expect(subject.get_uncommitted_events[0]).to be account_opened
      expect(subject.get_uncommitted_events[1]).to be account_renamed
    end
  end
  
  describe "new_entity" do
    it "should create entity instance initialized with self" do
      entity_class = double(:entity_class)
      entity = double(:entity)
      expect(entity_class).to receive(:new).with(subject).and_return(entity)
      expect(subject.send(:new_entity, entity_class)).to be entity
    end
    
    it "should also pass all arguments when creating the entity" do
      entity_class = double(:entity_class)
      entity = double(:entity)
      expect(entity_class).to receive(:new).with(subject, 'arg-1', 'arg-2').and_return(entity)
      expect(subject.send(:new_entity, entity_class, 'arg-1', 'arg-2')).to be entity
    end
  end
  
  describe "clear_uncommitted_events" do
    it "should empty uncommitted events" do
      account_opened  = double(:account_opened, :version= => nil)
      account_renamed = double(:account_renamed, :version= => nil)
      allow(subject).to receive(:apply_event)
      subject.send(:raise_event, account_opened)
      subject.send(:raise_event, account_renamed)
      
      subject.clear_uncommitted_events
      expect(subject.get_uncommitted_events).to be_empty
    end
  end
end
