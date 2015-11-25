module CommonDomain::UnitOfWork
  class AbstractUnitOfWork
    attr_reader :repository
    def initialize(repository)
      @repository = repository
      @tracked_aggregates = {}
    end
    
    def get_by_id aggregate_class, aggregate_id
      @tracked_aggregates[aggregate_id] ||= @repository.get_by_id aggregate_class, aggregate_id
    end
    
    def add_new aggregate
      @tracked_aggregates[aggregate.aggregate_id] = aggregate
    end
    
    def commit(headers)
      raise 'Not implemented'
    end

    def self.begin_unit_of_work(repository, headers, &block)
      uow = new repository
      result = yield(uow)
      uow.commit headers
      result
    end
  end
  
  #
  # This module presents non atomic Unit of Work. Affected aggregates will be sequentally saved one by one.
  # This kind of unit of work should be used if the cost of the possible failure when saving each aggregate is very low.
  #  
  module NonAtomic
    class NonAtomicUnitOfWork < CommonDomain::UnitOfWork::AbstractUnitOfWork
      def commit(headers)
        @tracked_aggregates.values.each do |aggregate|
          @repository.save aggregate, headers
        end
      end
    end

    def begin_unit_of_work(headers, &block)
      NonAtomicUnitOfWork.begin_unit_of_work repository_factory.create_repository, headers, &block
    end
  end
  
  #
  # This module presents atomic unit of work. Affected aggregates will be saved in scope of transaction
  # Please use this module only if the underlying persistence engine supports transactions
  #
  module Atomic
    class AtomicUnitOfWork < NonAtomic::NonAtomicUnitOfWork
      def initialize(*args)
        super
        ensure_transactions_supported!
      end
      
      def commit(headers)
        @repository.event_store.transaction do
          super
        end
      end
      
      private def ensure_transactions_supported!
        raise 'Can not use AtomicUnitOfWork. Underlying persistence engine does not support transactions.' unless repository.event_store.persistence_engine.supports_transactions?
      end
    end
  
    def begin_unit_of_work(headers, &block)
      AtomicUnitOfWork.begin_unit_of_work repository_factory.create_repository, headers, &block
    end
  end
end