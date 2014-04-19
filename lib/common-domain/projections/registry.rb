module CommonDomain::Projections
  class Registry
    class DuplicateKeyError < ::StandardError
    end
    
    def initialize(event_bus)
      @event_bus = event_bus
      @projections = {}
    end
    
    def for_each(&block)
      @projections.each_value &block
    end
    
    def register(key, read_model)
      raise DuplicateKeyError.new "Read model with the key '#{key}' already registered." if @projections.key?(key)
      @projections[key] = read_model
      @event_bus.register read_model
    end
    
    def respond_to?(symbol, *args)
      return true if @projections.key?(symbol)
      super(symbol, *args)
    end
    
    def method_missing(name, *args)
      if @projections.key?(name)
        @projections[name]
      else
        super(name, *args)
      end
    end
  end
end