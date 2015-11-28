module CommonDomain
  class PersistenceFactory
    def initialize(event_store, builder, snapshots_repository = nil)
      @event_store, @builder, @snapshots_repository = event_store, builder, snapshots_repository
    end
    
    def create_repository
      Persistence::Repository.new(@event_store, @builder, @snapshots_repository)
    end

    def begin_unit_of_work(headers, &block)
      uow = CommonDomain::UnitOfWork.new(create_repository)
      result = yield(uow)
      uow.commit headers
      result
    end
  end
end