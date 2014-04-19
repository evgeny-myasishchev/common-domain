module CommonDomain
  autoload :Aggregate, 'common-domain/aggregate'
  autoload :CommandDispatcher, 'common-domain/command-dispatcher'
  autoload :CommandHandler, 'common-domain/command-handler'
  autoload :CommandResult, 'common-domain/command-result'
  autoload :Command, 'common-domain/command'
  autoload :DomainContext, 'common-domain/domain-context'
  autoload :DomainEvent, 'common-domain/domain-event'
  autoload :Entity, 'common-domain/entity'
  autoload :EventBus, 'common-domain/event-bus'
  module Infrastructure
    autoload :AggregateId, 'common-domain/infrastructure/aggregate-id'
    autoload :MessagesHandler, 'common-domain/infrastructure/messages-handler'
    autoload :MessagesRouter, 'common-domain/infrastructure/messages-router'
  end
  autoload :Logger, 'common-domain/logger'
  autoload :Persistence, 'common-domain/persistence'
  module Projections
    autoload :Base, 'common-domain/projections/base'
    autoload :Registry, 'common-domain/projections/registry'
    autoload :SqlProjection, 'common-domain/projections/sql-projection'
  end
end