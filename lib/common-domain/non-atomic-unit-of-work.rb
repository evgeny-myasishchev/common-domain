#
# This module presents non atomic Unit of Work
# It is intended to be used in cases when your command affects multiple aggregates
# and you don't care mutch about failures when saving affected aggregates.
# The cost of the possible failure when saving each aggregate should be low.
# Please think carefully before using this Unit of Work
#
module CommonDomain::NonAtomicUnitOfWork
  class UnitOfWork
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
      @tracked_aggregates.values.each do |aggregate|
        @repository.save aggregate, headers
      end
    end
  end
  
  def begin_unit_of_work(headers, &block)
    uow = UnitOfWork.new repository
    result = yield(uow)
    uow.commit headers
    result
  end
end