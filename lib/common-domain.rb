module CommonDomain
  require_relative 'common-domain/aggregate'
  require_relative 'common-domain/application-context'
  require_relative 'common-domain/bootstrap'
  require_relative 'common-domain/command-dispatcher'
  require_relative 'common-domain/command-handler'
  require_relative 'common-domain/command-result'
  require_relative 'common-domain/command'
  require_relative 'common-domain/commit-context'
  require_relative 'common-domain/domain-context'
  require_relative 'common-domain/domain-event'
  require_relative 'common-domain/entity'
  require_relative 'common-domain/event-bus'
  module Messages
    require_relative 'common-domain/messages/dsl'
    require_relative 'common-domain/messages/message'
    require_relative 'common-domain/messages/messages-handler'
    require_relative 'common-domain/messages/messages-router'
  end
  module Infrastructure
    require_relative 'common-domain/infrastructure/aggregate-id'
    require_relative 'common-domain/infrastructure/connection-spec-helper'
  end
  require_relative 'common-domain/logger'
  require_relative 'common-domain/persistence'
  require_relative 'common-domain/unit-of-work'
  module Projections
    require_relative 'common-domain/projections/activerecord'
    require_relative 'common-domain/projections/base'
    require_relative 'common-domain/projections/registry'
  end
end