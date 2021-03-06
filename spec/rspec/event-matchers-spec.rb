require 'spec-helper'

describe "event-matchers" do
  module Events
    include CommonDomain::DomainEvent::DSL
    event :AggregateCreated, :aggregate_id, :name, :description
    event :AggregateRemoved, :aggregate_id
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
      aggregate.raise_event Events::AggregateCreated.new "aggregate-id", 'name', 'descr'
      expect(aggregate).to have_uncommitted_events
    end
    
    it "should match exact number if specified" do
      matcher = have_uncommitted_events exactly: 2
      aggregate.raise_event Events::AggregateCreated.new "aggregate-id", 'name', 'descr'
      expect(matcher.matches?(aggregate)).to be_falsey
      aggregate.raise_event Events::AggregateCreated.new "aggregate-id", 'name', 'descr'
      expect(matcher.matches?(aggregate)).to be_truthy
    end
    
    it "should not match if actual has no uncommitted events" do
      expect(aggregate).not_to have_uncommitted_events
    end
    
    it "should provide failure message for should" do
      matcher = have_uncommitted_events
      matcher.matches? aggregate
      expect(matcher.failure_message).to eql %(expected that an aggregate "#{aggregate}" has uncommitted events)
    end
    
    it "should provide failure message for should with exact match" do
      matcher = have_uncommitted_events exactly: 3
      matcher.matches? aggregate
      expect(matcher.failure_message).to eql %(expected that an aggregate "#{aggregate}" has exactly 3 uncommitted events\ngot: 0)
    end
    
    it "should provide failure message for should_not" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-id", 'name', 'descr'
      aggregate.raise_event Events::AggregateCreated.new "aggregate-id", 'name', 'descr'
      matcher = have_uncommitted_events
      matcher.matches? aggregate
      expect(matcher.failure_message_when_negated).to eql %(expected that an aggregate "#{aggregate}" has no uncommitted events\ngot: 2)
    end
        
    it "should provide failure message for should_not with exact match" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-id", 'name', 'descr'
      aggregate.raise_event Events::AggregateCreated.new "aggregate-id", 'name', 'descr'
      matcher = have_uncommitted_events exactly: 2
      matcher.matches? aggregate
      expect(matcher.failure_message_when_negated).to eql %(expected that an aggregate "#{aggregate}" has no 2 uncommitted events)
    end
  end
  
  describe "raise_event" do
    it "should setup a raise_event expectation" do
      expect(aggregate).to raise_event Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1')
      aggregate.send(:raise_event, Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1'))
    end
    
    it "should fail if the events does not match" do
      expect(aggregate).to raise_event Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1')
      expect {
        aggregate.send(:raise_event, Events::AggregateCreated.new("aggregate-2", 'Name 2', 'Description 2'))
      }.to raise_error(RSpec::Mocks::MockExpectationError)
      reset aggregate
    end
    
    it "should setup a negative matcher for should_not" do
      expect(aggregate).not_to raise_event Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1')
      expect { 
        aggregate.send(:raise_event, Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1'))
      }.to raise_error(RSpec::Mocks::MockExpectationError)
    end
    
    it "should setup a negative matcher without any arg if no event supplied" do
      expect(aggregate).not_to raise_event
      expect { 
        aggregate.send(:raise_event, Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1'))
      }.to raise_error(RSpec::Mocks::MockExpectationError)
    end
  end
  
  describe "apply_event" do
    it "should setup a apply_event expectation" do
      expect(aggregate).to apply_event Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1')
      aggregate.send(:apply_event, Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1'))
    end
    
    it "should fail if the events does not match" do
      expect(aggregate).to apply_event Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1')
      expect {
        aggregate.send(:apply_event, Events::AggregateCreated.new("aggregate-2", 'Name 2', 'Description 2'))
      }.to raise_error(RSpec::Mocks::MockExpectationError)
      reset aggregate
    end
    
    it "should setup a negative matcher for should_not" do
      expect(aggregate).not_to apply_event Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1')
      expect { 
        aggregate.send(:apply_event, Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1'))
      }.to raise_error(RSpec::Mocks::MockExpectationError)
    end
    
    it "should setup a negative matcher without any arg if no event supplied" do
      expect(aggregate).not_to apply_event
      expect { 
        aggregate.send(:apply_event, Events::AggregateCreated.new("aggregate-1", 'Name 1', 'Description 1'))
      }.to raise_error(RSpec::Mocks::MockExpectationError)
    end
  end
  
  describe "have_one_uncommitted_event" do
    it "should match if actual has one uncommitted event of specified kind" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1", 'name', 'descr'
      expect(aggregate).to have_one_uncommitted_event Events::AggregateCreated, aggregate_id: "aggregate-1", name: 'name', description: 'descr'
    end
    
    it "should match if all attributes of the uncommitted event match" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1", "aggregate-1", "aggregate-1 description"
      expect(aggregate).to have_one_uncommitted_event Events::AggregateCreated, aggregate_id: "aggregate-1", name: "aggregate-1", description: "aggregate-1 description"
    end
    
    it "should not match if actual has no uncommitted events" do
      expect(aggregate).not_to have_one_uncommitted_event
    end
    
    it "should not match if actual has more than one uncommitted event" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1", 'name', 'descr'
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1", 'name', 'descr'
      expect(aggregate).not_to have_one_uncommitted_event
    end
    
    it "should match if actual has more than one uncommitted event and index is specified" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1", 'name-1', 'descr-1'
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1", 'name-2', 'descr-2'
      expect(aggregate).to have_one_uncommitted_event Events::AggregateCreated, {aggregate_id: "aggregate-1", name: 'name-1', description: 'descr-1'}, at_index: 0
      expect(aggregate).to have_one_uncommitted_event Events::AggregateCreated, {aggregate_id: "aggregate-1", name: 'name-2', description: 'descr-2'}, at_index: 1
    end
    
    it "should not match if attributes of the event are not equal" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1", "aggregate-100", "aggregate-1 description"
      expect(aggregate).not_to have_one_uncommitted_event Events::AggregateCreated, aggregate_id: "aggregate-1", name: "aggregate-1", description: "aggregate-1 description"
    end
    
    it "should fail if some attributes are not specified" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1", "aggregate-100", "aggregate-1 description"
      expect { have_one_uncommitted_event(Events::AggregateCreated, aggregate_id: "aggregate-1").matches?(aggregate) }.
        to raise_error(ArgumentError, 'Missing attributes: name, description')
    end
    
    it "should fail if wrong attributes are specified" do
      aggregate.raise_event Events::AggregateCreated.new "aggregate-1", "aggregate-100", "aggregate-1 description"
      expect { have_one_uncommitted_event(Events::AggregateCreated, aggregate_id: "aggregate-1", name: '', description: '', wrong1: 'value1', wrong2: 'value2').matches?(aggregate) }.
        to raise_error(ArgumentError, 'Unknown attributes: wrong1, wrong2')
    end
    
    describe "failure_message" do
      it "should be specific if number of uncommitted events is not one and no index" do
        aggregate.raise_event Events::AggregateCreated.new "aggregate-1", 'name', 'descr'
        aggregate.raise_event Events::AggregateCreated.new "aggregate-1", 'name', 'descr'
        matcher = have_one_uncommitted_event
        matcher.matches? aggregate
        expect(matcher.failure_message).to eql %(expected: aggregate "#{aggregate}" has 1 uncommitted event\ngot: 2)
      end
      
      it "should be specific if event type is different" do
        aggregate.raise_event Events::AggregateCreated.new "aggregate-1", 'name', 'descr'
        matcher = have_one_uncommitted_event Events::AggregateRemoved
        matcher.matches? aggregate
        expect(matcher.failure_message).to eql %(expected that the event to be an instance of Events::AggregateRemoved but got Events::AggregateCreated)
      end
      
      it "should be specific if event type is different with index" do
        aggregate.raise_event Events::AggregateCreated.new "aggregate-1", 'name', 'descr'
        aggregate.raise_event Events::AggregateRemoved.new 'aggregate-1'
        matcher = have_one_uncommitted_event Events::AggregateRemoved, {aggregate_id: 'aggregate-1'}, at_index: 0
        matcher.matches? aggregate
        expect(matcher.failure_message).to eql %(expected that the event to be an instance of Events::AggregateRemoved but got Events::AggregateCreated)
      end
      
      it "should be specific if attributes are different" do
        aggregate.raise_event Events::AggregateCreated.new "aggregate-1", "aggregate-1", "aggregate-1 description"
        matcher = have_one_uncommitted_event Events::AggregateCreated, aggregate_id: "aggregate-1", name: "aggregate-2", description: "aggregate-1 description"
        matcher.matches? aggregate
        expect(matcher.failure_message).to eql %(expected: attribute "name" to equal "aggregate-2"\ngot: "aggregate-1")
      end
      
      it "should be specific if attributes are different with index" do
        aggregate.raise_event Events::AggregateCreated.new "aggregate-1", "aggregate-1", "aggregate-1 description"
        aggregate.raise_event Events::AggregateRemoved.new 'aggregate-1'
        matcher = have_one_uncommitted_event Events::AggregateCreated, {aggregate_id: "aggregate-1", name: "aggregate-2", description: "aggregate-1 description"}, at_index: 0
        matcher.matches? aggregate
        expect(matcher.failure_message).to eql %(expected: attribute "name" to equal "aggregate-2"\ngot: "aggregate-1")
      end
    end
  end
end