require 'spec-helper'

describe "Integration - CommonDomain::Projections::SqlProjection" do
  include SqlConnectionHelper
  let(:connection) { sqlite_memory_connection }
  
  module Events
    include CommonDomain::DomainEvent::DSL
    event :EmployeeCreated, :name
    event :EmployeeRenamed, :name
    event :EmployeeRemoved
  end
  
  class EmployeesProjection < CommonDomain::Projections::Sql
    on Events::EmployeeCreated do |event|
      tables.employees.insert id: event.aggregate_id, name: event.name
    end
      
    on Events::EmployeeRenamed do |event|
      tables.employees.where(id: event.aggregate_id).update(name: event.name)
    end
    
    on Events::EmployeeRemoved do |event|
      tables.employees.where(id: event.aggregate_id).delete
    end
    
    setup_schema do |schema|
      schema.table :employees, :employees_projection do
        String :id, :primary_key=>true, :size => 50, :null=>false
        String :name, :size => 50, :null=>false
      end
    end
  end
  
  class IntegrationContext < CommonDomain::DomainContext
    def with_event_store
      bootstrap_event_store do |with|
        with.log4r_logging
        with.in_memory_persistence
      end
    end
    
    def with_projections(connection)
      bootstrap_projections do |projections|
        projections.register :accounts, EmployeesProjection.new(connection)
      end
    end
  end
  
  before(:each) do
    @app = IntegrationContext.new do |bootstrap|
      bootstrap.with_event_bus
      bootstrap.with_event_store
      bootstrap.with_projections(connection)
      bootstrap.with_projections_initialization
    end
  end
  
  after(:each) do
    @app.event_store.dispatcher.stop
  end
  
  it "should setup schema of the projection" do
    expect(connection).to have_table(:employees_projection) do |table|
      expect(table).to have_column(:id, primary_key: true, allow_null: false)
      expect(table).to have_column(:name, allow_null: false)
    end
  end
  
  it "should route domain messages to the projection" do
    stream = @app.event_store.open_stream('stream-1')
    stream.add EventStore::EventMessage.new Events::EmployeeCreated.new('stream-1', 'Employee 1')
    stream.add EventStore::EventMessage.new Events::EmployeeCreated.new('stream-2', 'Employee 2')
    stream.add EventStore::EventMessage.new Events::EmployeeCreated.new('stream-3', 'Employee 3')
    stream.commit_changes
    
    stream.add EventStore::EventMessage.new Events::EmployeeRenamed.new('stream-2', 'New name 2')
    stream.commit_changes
    
    stream.add EventStore::EventMessage.new Events::EmployeeRemoved.new('stream-3')
    stream.commit_changes
    
    @app.event_store.dispatcher.stop
    
    expect(connection[:employees_projection][id: 'stream-1']).to eql id: 'stream-1', name: 'Employee 1'
    expect(connection[:employees_projection][id: 'stream-2']).to eql id: 'stream-2', name: 'New name 2'
    expect(connection[:employees_projection][id: 'stream-3']).to be_nil
  end
end