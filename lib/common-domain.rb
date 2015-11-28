module CommonDomain
  #Must go first since can be used by others
  require_relative 'common-domain/loggable'
  
  require_relative 'common-domain/aggregate'
  require_relative 'common-domain/command-dispatcher'
  require_relative 'common-domain/command-handler'
  require_relative 'common-domain/command'
  require_relative 'common-domain/domain-event'
  require_relative 'common-domain/event-bus'
  module Messages
    require_relative 'common-domain/messages/dsl'
    require_relative 'common-domain/messages/message'
    require_relative 'common-domain/messages/messages-handler'
    require_relative 'common-domain/messages/messages-router'
  end
  module Infrastructure
    require_relative 'common-domain/infrastructure/connection-spec-helper'
  end
  require_relative 'common-domain/persistence-factory'
  require_relative 'common-domain/persistence'
  require_relative 'common-domain/unit-of-work'
  module Projections
    require_relative 'common-domain/projections/activerecord'
    require_relative 'common-domain/projections/base'
  end
end