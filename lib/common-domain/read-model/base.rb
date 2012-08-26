module CommonDomain::ReadModel
  class Base
    include CommonDomain::Infrastructure::MessagesHandler
    
    def setup
      raise "Not implemented"
    end
    
    def purge!
      raise "Not implemented"
    end
    
    def rebuild_required?
      raise "Not implemented"
    end
  end
end