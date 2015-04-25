module CommonDomain
  class EventBus
    include CommonDomain::Messages::MessagesRouter
    
    alias_method :publish, :route
  end
end