module IntegrationSpecsAncillary
  module Domain
    module Events
      include CommonDomain::DomainEvent::DSL
      event :EmployeeRegistered, :aggregate_id
      event :EmployeeResigned, :aggregate_id
    end

    module Aggregates
      class Employee < CommonDomain::Aggregate
        def register employee_id
          raise_event Events::EmployeeRegistered.new employee_id
        end

        def resign
          raise_event Events::EmployeeResigned.new aggregate_id
        end

        on Events::EmployeeRegistered do |event|
          @aggregate_id = event.aggregate_id
        end
        on Events::EmployeeResigned do |event|
        end
      end
    end
  end

  def self.included(base)
    base.class_eval do
      let(:event_store) {
        EventStore.bootstrap do |with|
          with.log4r_logging
          with.sql_persistence adapter: 'sqlite', database: ':memory:' #Using memory here to see more output in the log file
        end
      }
      let(:aggregates_builder) { CommonDomain::Persistence::AggregatesBuilder.new }
    end
  end
  
  def fetch_events
    events = []
    event_store.for_each_commit { |c| events.concat c.events }
    events
  end
end