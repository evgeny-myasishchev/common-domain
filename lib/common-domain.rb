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
    autoload :ConnectionSpecHelper, 'common-domain/infrastructure/connection-spec-helper'
    autoload :MessagesHandler, 'common-domain/infrastructure/messages-handler'
    autoload :MessagesRouter, 'common-domain/infrastructure/messages-router'
  end
  autoload :Logger, 'common-domain/logger'
  autoload :NonAtomicUnitOfWork, 'common-domain/non-atomic-unit-of-work'
  autoload :Persistence, 'common-domain/persistence'
  module Projections
    autoload :ActiveRecord, 'common-domain/projections/activerecord'
    autoload :Base, 'common-domain/projections/base'
    autoload :Registry, 'common-domain/projections/registry'
    autoload :Sql, 'common-domain/projections/sql'
  end
end