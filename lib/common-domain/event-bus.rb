module CommonDomain
  class EventBus
    include CommonDomain::Infrastructure::MessagesRouter
    
    alias_method :publish, :route
  end
end