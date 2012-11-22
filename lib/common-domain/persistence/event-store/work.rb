module CommonDomain::Persistence::EventStore
  class Work < CommonDomain::Persistence::Repository::AbstractWork
    attr_reader :repository
    Log = CommonDomain::Logger.get("common-domain::persistence::event-store-work")
    def initialize(event_store, builder)
      Log.debug "Starting new work..."
      @aggregates = {}
      @work = event_store.begin_work
      @repository = Repository.new @work, builder
    end

    def get_by_id(aggregate_class, id)
      # We don't maintain identify map using aggregate_class + id because id is normally a guid which is unlikelly to duplicate
      return @aggregates[id] if @aggregates.key?(id)
      @aggregates[id] = @repository.get_by_id(aggregate_class, id)
    end

    def add_new(aggregate)
      aggregate_id = aggregate.aggregate_id
      raise "Can not add new aggregate because aggregate_id is not assigned yet." if aggregate_id.nil?
      raise "Another aggregate with id '#{aggregate_id}' already added." if @aggregates.key?(aggregate_id)
      @aggregates[aggregate_id] = aggregate
    end

    def commit_changes(headers = {})
      Log.debug "Committing work changes..."
      @aggregates.values.each { |aggregate| @repository.save(aggregate) }
      @work.commit_changes headers
      Log.debug "Work changes commited."
      nil
    end
  end
end