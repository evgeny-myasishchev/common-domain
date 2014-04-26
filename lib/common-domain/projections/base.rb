module CommonDomain::Projections
  class Base
    include CommonDomain::Infrastructure::MessagesHandler
    
    #Setup persistence schema if needed
    def setup
      raise "Not implemented"
    end
    
    #Remove everything related to the projection including schema (optional).
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
    
    # Factory method. Used to build the projection. Simplifies the registration.
    def self.create_projection(*args)
      new(*args)
    end
  end
end