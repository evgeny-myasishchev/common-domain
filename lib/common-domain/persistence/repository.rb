module CommonDomain::Persistence
  class Repository
    Log = CommonDomain::Logger.get("common-domain::persistence::repository")
    
    class AbstractWork
      def get_by_id(aggregate_class, id)
        raise "Not implemented"
      end
      
      def add_new(aggregate)
        raise "Not implemented"
      end
      
      def commit_changes(headers = {})
        raise "Not implemented"
      end
    end
    
    def get_by_id(aggregate_class, id)
      raise "Not implemented"
    end
    
    def save(aggregate, headers = {})
      raise "Not implemented"
    end
    
    def begin_work(headers = {}, &block)
      Log.debug "Starting new work..."
      work = create_work
      yield(work)
      Log.debug "Committing work changes..."
      work.commit_changes headers
      Log.debug "Work changes commited."
      nil
    end
    
    protected
      def create_work
        raise "Abstract method. Needs to be implemented and should return an instance of AbstractWork."
      end
  end
end