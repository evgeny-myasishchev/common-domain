module CommonDomain::Projections
  module Base
    def identifier
      self.class.name
    end
    
    #Purge projection related data
    def purge!
      raise "Not implemented"
    end
    
    def self.included(receiver)
      receiver.send :include, CommonDomain::Messages::MessagesHandler
    end
  end
end