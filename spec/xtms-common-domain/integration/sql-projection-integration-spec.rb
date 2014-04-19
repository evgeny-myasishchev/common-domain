require 'spec-helper'

describe "Integration - CommonDomain::Projections::SqlProjection" do
  include SqlConnectionHelper
  let(:connection) { sqlite_memory_connection }
  
  class EmployeesProjection < CommonDomain::Projections::SqlProjection
    setup_schema do |schema|
      schema.table :employees, :employees_projection do
        String :id, :primary_key=>true, :size => 50, :null=>false
        String :name, :size => 50, :null=>false
      end
    end
  end
  
  module Events
    include CommonDomain::DomainEvent::DSL
    event :EmployeeCreated, :name
    event :EmployeeRenamed, :name
    event :EmployeeRemoved
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
      bootstrap.with_events_bus
      bootstrap.with_event_store
      bootstrap.with_projections(connection)
      bootstrap.with_projections_initialization
    end
  end
  
  it "should setup schema of the projection" do
    
  end
end