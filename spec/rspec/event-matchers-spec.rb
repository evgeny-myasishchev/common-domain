require 'spec-helper'

describe "event-matchers" do
  class Events
    include CommonDomain::DomainEvent::DSL
    event :AggregateCreated, :name, :description
    event :AggregateRemoved
  end
  class Aggregate < CommonDomain::Aggregate
    def raise_event(*args)
      super *args
    end
    on(Events::AggregateCreated) { |event| }
    on(Events::AggregateRemoved) { |event| }
  end
  
  let(:aggregate) { Aggregate.new }
  
  describe "have_uncommitted_events" do
    it "should match if actual has uncommitted events" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-id"
      aggregate.should have_uncommitted_events
    end
    
    it "should not match if actual has no uncommitted events" do
      aggregate.should_not have_uncommitted_events
    end
    
    it "should provide failure message for should" do
      matcher = have_uncommitted_events
      matcher.matches? aggregate
      matcher.failure_message_for_should.should == %(expected that an aggregate "#{aggregate}" has uncommitted events.)
    end
    
    it "should provide failure message for should_not" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-id"
      aggregate.raise_event Events::AggregateCreated.new "aggregate-id"
      matcher = have_uncommitted_events
      matcher.matches? aggregate
      matcher.failure_message_for_should_not.should == %(expected that an aggregate "#{aggregate}" has no uncommitted events\ngot: 2)
    end
  end
  
  describe "raise_event" do
    it "should setup a raise_event expectation" do
      aggregate.should raise_event Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1')
      aggregate.send(:raise_event, Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1'))
    end
    
    it "should fail if the events does not match" do
      aggregate.should raise_event Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1')
      lambda {
        aggregate.send(:raise_event, Events::AggregateCreated.new("aggregate-2", 'Name 2', 'Description 2'))
      }.should raise_error(RSpec::Mocks::MockExpectationError)
      aggregate.rspec_reset
    end
  end
  
  describe "have_one_uncommitted_event" do
    it "should match if actual has one uncommitted event of specified kind" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1"
      aggregate.should have_one_uncommitted_event Events::AggregateCreated, aggregate_id: "aggregate-1"
    end
    
    it "should match if all attributes of the uncommitted event match" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1", "aggregate-1", "aggregate-1 description"
      aggregate.should have_one_uncommitted_event Events::AggregateCreated, aggregate_id: "aggregate-1", name: "aggregate-1", description: "aggregate-1 description"
    end
    
    it "should not match if actual has no uncommitted events" do
      aggregate.should_not have_one_uncommitted_event
    end
    
    it "should not match if actual has more than one uncommitted event" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1"
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1"
      aggregate.should_not have_one_uncommitted_event
    end
    
    it "should not match if attributes of the event are not equal" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1", "aggregate-100", "aggregate-1 description"
      aggregate.should_not have_one_uncommitted_event Events::AggregateCreated, aggregate_id: "aggregate-1", name: "aggregate-1", description: "aggregate-1 description"
    end
    
    describe "failure_message_for_should" do
      it "should be specific if number of uncommitted events is not one" do
        aggregate.raise_event Events::AggregateCreated.new "aggregate-1"
        aggregate.raise_event Events::AggregateCreated.new "aggregate-1"
        matcher = have_one_uncommitted_event
        matcher.matches? aggregate
        matcher.failure_message_for_should.should eql %(expected: aggregate "#{aggregate}" has 1 uncommitted event\ngot: 2)
      end
      
      it "should be specific if event type is different" do
        aggregate.raise_event Events::AggregateCreated.new "aggregate-1"
        matcher = have_one_uncommitted_event Events::AggregateRemoved
        matcher.matches? aggregate
        matcher.failure_message_for_should.should eql %(expected that the event to be an instance of Events::AggregateRemoved but got Events::AggregateCreated)
      end
      
      it "should be specific if attributes are different" do
        aggregate.raise_event Events::AggregateCreated.new "aggregate-1", "aggregate-1", "aggregate-1 description"
        matcher = have_one_uncommitted_event Events::AggregateCreated, aggregate_id: "aggregate-1", name: "aggregate-2", description: "aggregate-1 description"
        matcher.matches? aggregate
        matcher.failure_message_for_should.should eql %(expected: attribute "name" to equal "aggregate-2"\ngot: "aggregate-1")
      end
    end
  end
end