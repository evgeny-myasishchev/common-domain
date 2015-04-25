module CommonDomain::Projections
  module Base
    #Setup persistence related stuff (like schema or any other means)
    def setup
      raise "Not implemented"
    end
    
    #Remove everything related to the projection (like data and possible schema).
    def cleanup!
      raise "Not implemented"
    end
    
    #Returns true if the projection requires rebuild.
    #It maybe because of the underlying persistence details has changed.
    def rebuild_required?
      raise "Not implemented"
    end
    
    #Returns true if projection requires setup. 
    #That is if the projection has never been setup before.
    def setup_required?
      raise "Not implemented"
    end
    
    def self.included(receiver)
      receiver.send :include, CommonDomain::Messages::MessagesHandler
    end
  end
end