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
  module ReadModel
    autoload :Base, 'common-domain/read-model/base'
    autoload :Registry, 'common-domain/read-model/registry'
    autoload :SqlReadModel, 'common-domain/read-model/sql-read-model'
  end
end