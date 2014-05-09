require 'spec-helper'

describe "Integration - CommonDomain::Projections::ActiveRecordProjection" do
  include ActiveRecordHelpers
  use_sqlite_activerecord_connection 'integration-ar-projections-spec.sqlite'
  let(:sequel_connection) { Sequel.connect adapter: "sqlite", database: @db_path.to_s }
  
  class Events
    include CommonDomain::DomainEvent::DSL
    event :EmployeeCreated, :name
    event :EmployeeRenamed, :name
    event :EmployeeRemoved
  end
  
  class EmployeesProjection < ActiveRecord::Base
    extend CommonDomain::Projections::ActiveRecord
    
    on Events::EmployeeCreated do |event|
      create! employee_id: event.aggregate_id, name: event.name
    end
      
    on Events::EmployeeRenamed do |event|
      where(employee_id: event.aggregate_id).update(name: event.name)
    end
    
    on Events::EmployeeRemoved do |event|
      where(employee_id: event.aggregate_id).delete_all
    end
    
    def self.ensure_schema!
      unless connection.table_exists? table_name
        connection.create_table(table_name) do |t|
          t.column :employee_id, :uuid
          t.column :name, :string, null: false
        end
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
    
    def with_projections
      bootstrap_projections do |projections|
        projections.register :employees, EmployeesProjection
      end
    end
  end
  
  before(:all) do
    EmployeesProjection.ensure_schema!
    @app = IntegrationContext.new do |bootstrap|
      bootstrap.with_event_bus
      bootstrap.with_event_store
      bootstrap.with_projections
      bootstrap.with_projections_initialization
    end
  end
  
  it "should route domain messages to the projection" do
    stream = @app.event_store.open_stream('stream-1')
    stream.add EventStore::EventMessage.new Events::EmployeeCreated.new('stream-1', 'Initial name')
    stream.commit_changes
    sequel_connection[:employees_projection][employee_id: 'stream-1'].should eql id: 'stream-1', name: 'Initial name'
    
    stream.add EventStore::EventMessage.new Events::EmployeeRenamed.new('stream-1', 'New name')
    stream.commit_changes
    sequel_connection[:employees_projection][employee_id: 'stream-1'].should eql id: 'stream-1', name: 'New name'
    
    stream.add EventStore::EventMessage.new Events::EmployeeRemoved.new('stream-1')
    stream.commit_changes
    sequel_connection[:employees_projection][employee_id: 'stream-1'].should be_nil
  end
end