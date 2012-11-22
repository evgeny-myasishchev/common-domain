require 'spec-helper'

describe "Integration - Common Domain - Event Store Work" do
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
  let(:repository) { CommonDomain::Persistence::EventStore::Repository.new(event_store, aggregates_builder) }
  
  subject { CommonDomain::Persistence::EventStore::Work.new event_store, aggregates_builder }
  
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
  
  it "should save newly added aggregates on commit changes" do
    emp1 = Aggregates::Employee.new
    emp1.register 'employee-1'
    emp2 = Aggregates::Employee.new
    emp2.register 'employee-2'
    subject.add_new emp1
    subject.add_new emp2
    subject.commit_changes
    
    dispatched_events.should have(2).items
    dispatched_events[0].body.aggregate_id.should eql 'employee-1'
    dispatched_events[1].body.aggregate_id.should eql 'employee-2'
  end
  
  it "should update all loaded aggregates" do
    emp1 = Aggregates::Employee.new
    emp1.register 'employee-1'
    emp2 = Aggregates::Employee.new
    emp2.register 'employee-2'
    repository.save emp1
    repository.save emp2
    dispatched_events.clear
    
    subject.get_by_id(Aggregates::Employee, 'employee-1').resign
    subject.get_by_id(Aggregates::Employee, 'employee-2').resign
    subject.commit_changes
    
    emp1_stream = event_store.open_stream('employee-1')
    emp1_stream.committed_events.should have(2).items
    emp1_stream.committed_events[1].body.should be_instance_of Evt::EmployeeResigned
    
    emp2_stream = event_store.open_stream('employee-2')
    emp2_stream.committed_events.should have(2).items
    emp2_stream.committed_events[1].body.should be_instance_of Evt::EmployeeResigned
    
    dispatched_events.should have(2).items
  end
  
  it "should save all the events even if dispatching failed" do
    emp1 = Aggregates::Employee.new
    emp1.register 'employee-1'
    emp2 = Aggregates::Employee.new
    emp2.register 'employee-2'
    subject.add_new emp1
    subject.add_new emp2
    @dispatch_hook = lambda { |evt| raise "Dispatching aborted."  }
    lambda { subject.commit_changes }.should raise_error("Dispatching aborted.")
    
    emp1_stream = event_store.open_stream('employee-1')
    emp1_stream.committed_events.should have(1).items
    emp1_stream.committed_events[0].body.should be_instance_of Evt::EmployeeRegistered
    
    emp2_stream = event_store.open_stream('employee-2')
    emp2_stream.committed_events.should have(1).items
    emp2_stream.committed_events[0].body.should be_instance_of Evt::EmployeeRegistered
  end
end