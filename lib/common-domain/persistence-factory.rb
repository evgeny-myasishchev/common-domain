module CommonDomain
  class PersistenceFactory
    def initialize(event_store, builder, snapshots_repository = nil)
      @event_store, @builder, @snapshots_repository = event_store, builder, snapshots_repository
      @hooks = []
    end
    
    def hook **hook
      @hooks << hook
    end
    
    def create_repository
      repo = Persistence::Repository.new(@event_store, @builder, @snapshots_repository)
      add_hooks repo
      repo
    end

    def begin_unit_of_work(headers, &block)
      uow = CommonDomain::UnitOfWork.new(create_repository)
      add_hooks uow
      result = yield(uow)
      uow.commit headers
      result
    end
    
    private def add_hooks(receiver)
      @hooks.each { |hook| receiver.hook hook }
    end
  end
end