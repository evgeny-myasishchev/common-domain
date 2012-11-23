module IntegrationSpecsAncillary
  module Domain
    module Events
      include CommonDomain::DomainEvent::DSL
      event :EmployeeRegistered
      event :EmployeeResigned
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
    end
  end
end