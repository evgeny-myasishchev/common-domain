require 'spec-helper'

describe "Integration - Common Domain - Event Store Repository" do
  let(:dispatched_events) { Array.new }

  let(:event_store) {
    EventStore.bootstrap do |with|
      with.log4r_logging
      with.sql_persistence adapter: 'sqlite', database: ':memory:' #Using memory here to see more output in the log file
      with.synchorous_dispatcher do |commit|
        commit.events.each { |event| 
          @dispatch_hook.call event unless @dispatch_hook.nil?
          dispatched_events << event 
        }
      end
    end
  }
  let(:aggregates_builder) { CommonDomain::Persistence::AggregatesBuilder.new }
  subject { CommonDomain::Persistence::EventStore::Repository.new(event_store, aggregates_builder) }
  
  module Evt
    include CommonDomain::DomainEvent::DSL
    event :EmployeeRegistered
    event :EmployeeResigned
  end
  
  module Aggregates
    class Employee < CommonDomain::Aggregate
      def register employee_id
        raise_event Evt::EmployeeRegistered.new employee_id
      end
      
      def resign
        raise_event Evt::EmployeeResigned.new aggregate_id
      end
      
      on Evt::EmployeeRegistered do |event|
        @aggregate_id = event.aggregate_id
      end
      on Evt::EmployeeResigned do |event|
      end
    end
  end
  
  it "should save new aggregates" do
    emp1 = Aggregates::Employee.new
    emp1.register 'employee-1'
    emp2 = Aggregates::Employee.new
    emp2.register 'employee-2'
    subject.save emp1
    subject.save emp2
    
    emp1_stream = event_store.open_stream('employee-1')
    emp1_stream.committed_events.should have(1).items
    emp1_stream.committed_events[0].body.should be_instance_of Evt::EmployeeRegistered
    
    emp2_stream = event_store.open_stream('employee-2')
    emp2_stream.committed_events.should have(1).items
    emp2_stream.committed_events[0].body.should be_instance_of Evt::EmployeeRegistered
    
    dispatched_events.should have(2).items
    dispatched_events[0].body.aggregate_id.should eql 'employee-1'
    dispatched_events[1].body.aggregate_id.should eql 'employee-2'
  end
  
  it "should update existing aggregates" do
    emp1 = Aggregates::Employee.new
    emp1.register 'employee-1'
    emp2 = Aggregates::Employee.new
    emp2.register 'employee-2'
    subject.save emp1
    subject.save emp2
    dispatched_events.clear
    
    emp1 = subject.get_by_id(Aggregates::Employee, 'employee-1')
    emp1.resign
    emp2 = subject.get_by_id(Aggregates::Employee, 'employee-2')
    emp2.resign
    
    subject.save(emp1)
    subject.save(emp2)
    
    emp1_stream = event_store.open_stream('employee-1')
    emp1_stream.committed_events.should have(2).items
    emp1_stream.committed_events[1].body.should be_instance_of Evt::EmployeeResigned
    
    emp2_stream = event_store.open_stream('employee-2')
    emp2_stream.committed_events.should have(2).items
    emp2_stream.committed_events[1].body.should be_instance_of Evt::EmployeeResigned
    
    dispatched_events.should have(2).items
  end
end