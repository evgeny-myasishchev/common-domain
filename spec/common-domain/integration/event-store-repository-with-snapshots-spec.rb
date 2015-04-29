require 'spec-helper'

module EventStoreRepositoryWithSnapshotsSpec
  include CommonDomain::Persistence::Snapshots
  class InMemorySnapshotsRepo < CommonDomain::Persistence::Snapshots::SnapshotsRepository
    def initialize
      @store = {}
    end
    
    def get(aggregate_id)
      @store[aggregate_id]
    end
    
    def add(snapshot)
      @store[snapshot.id] = snapshot
    end
  end

  class Domain
    include IntegrationSpecsAncillary::Domain
    
    module Events
      include CommonDomain::DomainEvent::DSL
      event :EmployeeRenamed, :aggregate_id, :new_name
    end
    
    class EmployeeWithSnapshot < Aggregates::Employee
      attr_reader :name
      attr_reader :applied_snapshot, :rename_events
      
      def rename new_name
        raise_event Events::EmployeeRenamed.new aggregate_id, new_name
      end

      on Events::EmployeeRenamed do |event|
        @rename_events = @rename_events || []
        @rename_events << event
        @name = event.new_name
      end
      
      def get_snapshot
        {name: name}
      end
      
      def apply_snapshot(snapshot)
        @applied_snapshot = snapshot
        @name = snapshot[:name]
      end
      
      def self.add_snapshot?(aggregate)
        aggregate.applied_events_number > 3
      end
    end
  end
  
  describe "Integration - Common Domain - Event Store Repository - Snapshots" do
    include IntegrationSpecsAncillary
    let(:snapshots_repo) { InMemorySnapshotsRepo.new }
    subject { CommonDomain::Persistence::EventStore::Repository.new(event_store, aggregates_builder, snapshots_repo) }
    let(:aggregate) { Domain::EmployeeWithSnapshot.new }
    
    before(:each) do
      aggregate.register 'employee-1'
      aggregate.rename 'name-rev-1'
      aggregate.rename 'name-rev-2'
    end
    
    describe 'save' do
      it 'should not add snapshot if add_snapshot? returns false' do
        subject.save aggregate
        expect(snapshots_repo.get('employee-1')).to be_nil
      end
    
      it 'should add a snapshot if add_snapshot? returns true' do
        aggregate.rename 'name-rev-3'
        subject.save aggregate
        snapshot = snapshots_repo.get 'employee-1'
        expect(snapshot).not_to be_nil
        expect(snapshot.id).to eql 'employee-1'
        expect(snapshot.version).to eql 4
        expect(snapshot.data).to eql({name: 'name-rev-3'})
      end
    end
    
    describe 'get_by_id' do
      before(:each) do
        aggregate.rename 'name-rev-3'
        subject.save aggregate
        snapshots_repo.add Snapshot.new 'employee-1', 2, {name: 'name-rev-1'}
        @aggregate = subject.get_by_id Domain::EmployeeWithSnapshot, 'employee-1'
      end
      
      it 'should rebuild the aggregate from snapshot if there is a snapshot' do
        expect(@aggregate.applied_snapshot).to eql({name: 'name-rev-1'})
      end
      
      it 'should apply all further events' do
        expect(@aggregate.rename_events.length).to eql 2
        expect(@aggregate.name).to eql 'name-rev-3'
        expect(@aggregate.version).to eql 4
      end
    end
  end
end