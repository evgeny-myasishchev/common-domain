require 'spec-helper'

describe "Integration - Common Domain - Event Store Repository" do
  include IntegrationSpecsAncillary
  class Domain
    include IntegrationSpecsAncillary::Domain
  end
  subject { CommonDomain::Persistence::EventStore::Repository.new(event_store, aggregates_builder) }
  
  it "should save new aggregates" do
    emp1 = Domain::Aggregates::Employee.new
    emp1.register 'employee-1'
    emp2 = Domain::Aggregates::Employee.new
    emp2.register 'employee-2'
    subject.save emp1
    subject.save emp2
    expect(emp1.get_uncommitted_events).to be_empty
    expect(emp2.get_uncommitted_events).to be_empty
    
    emp1_stream = event_store.open_stream('employee-1')
    expect(emp1_stream.committed_events.length).to eql(1)
    expect(emp1_stream.committed_events[0]).to be_instance_of Domain::Events::EmployeeRegistered
    
    emp2_stream = event_store.open_stream('employee-2')
    expect(emp2_stream.committed_events.length).to eql(1)
    expect(emp2_stream.committed_events[0]).to be_instance_of Domain::Events::EmployeeRegistered
  end

  it "should update existing aggregates" do
    emp1 = Domain::Aggregates::Employee.new
    emp1.register 'employee-1'
    emp2 = Domain::Aggregates::Employee.new
    emp2.register 'employee-2'
    subject.save emp1
    subject.save emp2
    
    emp1 = subject.get_by_id(Domain::Aggregates::Employee, 'employee-1')
    emp1.resign
    emp2 = subject.get_by_id(Domain::Aggregates::Employee, 'employee-2')
    emp2.resign
    
    subject.save(emp1)
    subject.save(emp2)
    expect(emp1.get_uncommitted_events).to be_empty
    expect(emp2.get_uncommitted_events).to be_empty
    
    emp1_stream = event_store.open_stream('employee-1')
    expect(emp1_stream.committed_events.length).to eql(2)
    expect(emp1_stream.committed_events[1]).to be_instance_of Domain::Events::EmployeeResigned
    
    emp2_stream = event_store.open_stream('employee-2')
    expect(emp2_stream.committed_events.length).to eql(2)
    expect(emp2_stream.committed_events[1]).to be_instance_of Domain::Events::EmployeeResigned
  end

  it "should check if aggregate exists" do
    expect(subject.exists?('employee-1')).to be_falsey
    
    emp = Domain::Aggregates::Employee.new
    emp.register 'employee-1'
    subject.save emp
    
    expect(subject.exists?('employee-1')).to be_truthy
  end
end