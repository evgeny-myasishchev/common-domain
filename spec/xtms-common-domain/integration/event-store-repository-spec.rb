require 'spec-helper'

describe "Integration - Common Domain - Event Store Repository" do
  include IntegrationSpecsAncillary
  Domain = IntegrationSpecsAncillary::Domain
  subject { CommonDomain::Persistence::EventStore::Repository.new(event_store, aggregates_builder) }
  
  it "should save new aggregates" do
    emp1 = Domain::Aggregates::Employee.new
    emp1.register 'employee-1'
    emp2 = Domain::Aggregates::Employee.new
    emp2.register 'employee-2'
    subject.save emp1
    subject.save emp2
    
    emp1_stream = event_store.open_stream('employee-1')
    emp1_stream.committed_events.should have(1).items
    emp1_stream.committed_events[0].body.should be_instance_of Domain::Events::EmployeeRegistered
    
    emp2_stream = event_store.open_stream('employee-2')
    emp2_stream.committed_events.should have(1).items
    emp2_stream.committed_events[0].body.should be_instance_of Domain::Events::EmployeeRegistered
    
    dispatched_events.should have(2).items
    dispatched_events[0].body.aggregate_id.should eql 'employee-1'
    dispatched_events[1].body.aggregate_id.should eql 'employee-2'
  end
  
  it "should update existing aggregates" do
    emp1 = Domain::Aggregates::Employee.new
    emp1.register 'employee-1'
    emp2 = Domain::Aggregates::Employee.new
    emp2.register 'employee-2'
    subject.save emp1
    subject.save emp2
    dispatched_events.clear
    
    emp1 = subject.get_by_id(Domain::Aggregates::Employee, 'employee-1')
    emp1.resign
    emp2 = subject.get_by_id(Domain::Aggregates::Employee, 'employee-2')
    emp2.resign
    
    subject.save(emp1)
    subject.save(emp2)
    
    emp1_stream = event_store.open_stream('employee-1')
    emp1_stream.committed_events.should have(2).items
    emp1_stream.committed_events[1].body.should be_instance_of Domain::Events::EmployeeResigned
    
    emp2_stream = event_store.open_stream('employee-2')
    emp2_stream.committed_events.should have(2).items
    emp2_stream.committed_events[1].body.should be_instance_of Domain::Events::EmployeeResigned
    
    dispatched_events.should have(2).items
  end
end