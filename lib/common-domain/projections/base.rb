module CommonDomain::Projections
  class Base
    include CommonDomain::Infrastructure::MessagesHandler
    
    #Setup persistence schema
    def setup
      raise "Not implemented"
    end
    
    #Remove everything related to the projection including schema.
    def cleanup!
      raise "Not implemented"
    end
    
    #Returns true if the projection requires rebuild.
    #It maybe because of underlying persistence details has changed.
    def rebuild_required?
      raise "Not implemented"
    end
    
    #Returns true if projection requires setup. 
    #That is if the projection has never been setup before.
    def setup_required?
      raise "Not implemented"
    end
  end
end