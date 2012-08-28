module CommonDomain::ReadModel
  class Base
    include CommonDomain::Infrastructure::MessagesHandler
    
    #Setup persistence schema
    def setup
      raise "Not implemented"
    end
    
    #Remove everything related to the read model including schema.
    def cleanup!
      raise "Not implemented"
    end
    
    #Returns true if the read model requires rebuild.
    #It maybe because of underlying persistence details has changed.
    def rebuild_required?
      raise "Not implemented"
    end
    
    #Returns true if read model requires setup. 
    #That is if the read model has never been setup before.
    def setup_required?
      raise "Not implemented"
    end
  end
end