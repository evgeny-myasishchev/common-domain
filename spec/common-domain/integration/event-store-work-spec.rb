require 'spec-helper'

describe "Integration - Common Domain - Event Store Work" do
  include IntegrationSpecsAncillary
  class Domain
    include IntegrationSpecsAncillary::Domain
  end
  
  let(:repository) { CommonDomain::Persistence::EventStore::Repository.new(event_store, aggregates_builder) }
  subject { CommonDomain::Persistence::EventStore::Work.new event_store, aggregates_builder }
  
  it "should save newly added aggregates on commit changes" do
    emp1 = Domain::Aggregates::Employee.new
    emp1.register 'employee-1'
    emp2 = Domain::Aggregates::Employee.new
    emp2.register 'employee-2'
    subject.add_new emp1
    subject.add_new emp2
    subject.commit_changes
    
    expect(dispatched_events.length).to eql(2)
    expect(dispatched_events[0].body.aggregate_id).to eql 'employee-1'
    expect(dispatched_events[1].body.aggregate_id).to eql 'employee-2'
  end
  
  it "should update all loaded aggregates" do
    emp1 = Domain::Aggregates::Employee.new
    emp1.register 'employee-1'
    emp2 = Domain::Aggregates::Employee.new
    emp2.register 'employee-2'
    repository.save emp1
    repository.save emp2
    dispatched_events.clear
    
    subject.get_by_id(Domain::Aggregates::Employee, 'employee-1').resign
    subject.get_by_id(Domain::Aggregates::Employee, 'employee-2').resign
    subject.commit_changes
    
    emp1_stream = event_store.open_stream('employee-1')
    expect(emp1_stream.committed_events.length).to eql(2)
    expect(emp1_stream.committed_events[1].body).to be_instance_of Domain::Events::EmployeeResigned
    
    emp2_stream = event_store.open_stream('employee-2')
    expect(emp2_stream.committed_events.length).to eql(2)
    expect(emp2_stream.committed_events[1].body).to be_instance_of Domain::Events::EmployeeResigned
    
    expect(dispatched_events.length).to eql(2)
  end
  
  it "should save all the events even if dispatching failed" do
    emp1 = Domain::Aggregates::Employee.new
    emp1.register 'employee-1'
    emp2 = Domain::Aggregates::Employee.new
    emp2.register 'employee-2'
    subject.add_new emp1
    subject.add_new emp2
    @dispatch_hook = lambda { |evt| raise "Dispatching aborted."  }
    expect(lambda { subject.commit_changes }).to raise_error("Dispatching aborted.")
    
    emp1_stream = event_store.open_stream('employee-1')
    expect(emp1_stream.committed_events.length).to eql(1)
    expect(emp1_stream.committed_events[0].body).to be_instance_of Domain::Events::EmployeeRegistered
    
    emp2_stream = event_store.open_stream('employee-2')
    expect(emp2_stream.committed_events.length).to eql(1)
    expect(emp2_stream.committed_events[0].body).to be_instance_of Domain::Events::EmployeeRegistered
  end
  
  describe "exists?" do
    it "should return if newly added aggregate exists" do
      expect(subject.exists?('employee-1')).to be_falsey
    
      emp = Domain::Aggregates::Employee.new
      emp.register 'employee-1'
      subject.add_new emp
    
      expect(subject.exists?('employee-1')).to be_truthy
    end
    
    it "should check if already persisted aggregate exists" do
      emp = Domain::Aggregates::Employee.new
      emp.register 'employee-1'
      repository.save emp
      expect(subject.exists?('employee-1')).to be_truthy
    end
  end
end