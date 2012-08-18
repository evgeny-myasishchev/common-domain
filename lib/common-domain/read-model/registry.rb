module CommonDomain::ReadModel
  class Registry
    class DuplicateKeyError < ::StandardError
    end
    
    def initialize(event_bus)
      @event_bus = event_bus
      @read_models = {}
    end
    
    def for_each(&block)
      @read_models.each_value &block
    end
    
    def register(key, read_model)
      raise DuplicateKeyError.new "Read model with the key '#{key}' already registered." if @read_models.key?(key)
      @read_models[key] = read_model
      @event_bus.register read_model
    end
    
    def respond_to?(symbol, *args)
      return true if @read_models.key?(symbol)
      super(symbol, *args)
    end
    
    def method_missing(name, *args)
      if @read_models.key?(name)
        @read_models[name]
      else
        super(name, *args)
      end
    end
  end
end