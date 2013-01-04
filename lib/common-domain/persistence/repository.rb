module CommonDomain::Persistence
  class Repository
    Log = CommonDomain::Logger.get("common-domain::persistence::repository")
    
    class AbstractWork
      def initialize
        @on_committed = []
      end
      
      def get_by_id(aggregate_class, id)
        raise "Not implemented"
      end
      
      def add_new(aggregate)
        raise "Not implemented"
      end
      
      def commit_changes(headers = {})
        raise "Not implemented"
      end
      
      # Register a callback that'll be called right after work changes are commited.
      def on_committed(&block)
        @on_committed << block
      end
      
      protected
        # Invokes all callbacks previously registered with on_committed method
        def notify_on_committed
          @on_committed.each { |block| block.call }
        end
    end
    
    def get_by_id(aggregate_class, id)
      raise "Not implemented"
    end
    
    def save(aggregate, headers = {})
      raise "Not implemented"
    end
    
    def begin_work(headers = {}, &block)
      work = create_work
      result = yield(work)
      work.commit_changes headers
      result
    end
    
    protected
      def create_work
        raise "Abstract method. Needs to be implemented and should return an instance of AbstractWork."
      end
  end
end