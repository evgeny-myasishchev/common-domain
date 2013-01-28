require 'spec-helper'

describe CommonDomain::Aggregate do
  subject { described_class.new "account-1" }
  describe "apply_event" do
    it "should process events" do
      event1 = mock(:event1, :version => 1)
      event2 = mock(:event2, :version => 2)
      
      subject.should_receive(:handle_message).with(event1)
      subject.should_receive(:handle_message).with(event2)
      
      subject.apply_event event1
      subject.apply_event event2
    end
    
    it "should set aggregate version to event version" do
      event1 = mock(:event1, :version => 1)
      event2 = mock(:event2, :version => 2)
      
      subject.stub(:handle_message)
      
      subject.apply_event event1
      subject.version.should eql 1
      subject.apply_event event2
      subject.version.should eql 2
    end
    
    it "should return self" do
      subject.stub(:handle_message)
      subject.apply_event(mock(:event1, :version => 1)).should be subject
    end
  end
  
  describe "raise_event" do
    it "should set event version to aggregate version + 1" do
      account_opened  = mock(:account_opened)
      subject.stub(:apply_event)
      subject.stub(:version) { 10 }
      account_opened.should_receive(:version=).with(11)
      subject.send(:raise_event, account_opened)
    end
    
    it "should apply event" do
      account_opened  = mock(:account_opened, :version= => nil)
      subject.should_receive(:apply_event).with(account_opened)
      subject.send(:raise_event, account_opened)
    end
    
    it "should return self" do
      subject.stub(:apply_event)
      subject.send(:raise_event, mock(:account_opened, :version= => nil)).should be subject
    end
    
    it "should add an event to uncommitted events" do
      account_opened  = mock(:account_opened, :version= => nil)
      account_renamed = mock(:account_renamed, :version= => nil)
      subject.stub(:apply_event)
      subject.send(:raise_event, account_opened)
      subject.send(:raise_event, account_renamed)
      
      subject.get_uncommitted_events.should have(2).items
      subject.get_uncommitted_events[0].should be account_opened
      subject.get_uncommitted_events[1].should be account_renamed
    end
  end
  
  describe "new_entity" do
    it "should create entity instance initialized with self" do
      entity_class = mock(:entity_class)
      entity = mock(:entity)
      entity_class.should_receive(:new).with(subject).and_return(entity)
      subject.send(:new_entity, entity_class).should be entity
    end
    
    it "should also pass all arguments when creating the entity" do
      entity_class = mock(:entity_class)
      entity = mock(:entity)
      entity_class.should_receive(:new).with(subject, 'arg-1', 'arg-2').and_return(entity)
      subject.send(:new_entity, entity_class, 'arg-1', 'arg-2').should be entity
    end
  end
  
  describe "clear_uncommitted_events" do
    it "should empty uncommitted events" do
      account_opened  = mock(:account_opened, :version= => nil)
      account_renamed = mock(:account_renamed, :version= => nil)
      subject.stub(:apply_event)
      subject.send(:raise_event, account_opened)
      subject.send(:raise_event, account_renamed)
      
      subject.clear_uncommitted_events
      subject.get_uncommitted_events.should be_empty
    end
  end
end
