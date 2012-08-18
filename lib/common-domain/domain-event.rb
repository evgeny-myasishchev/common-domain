module CommonDomain
  class DomainEvent
    attr_reader :aggregate_id
    attr_accessor :version
    def initialize(aggregate_id, attributes = {})
      @aggregate_id = aggregate_id
      @version      = 0
      attributes.each_key { |key| instance_variable_set("@#{key}", attributes[key]) }
    end
    
    def ==(other)
      aggregate_id == other.aggregate_id && version == other.version
    end
    
    def eql?(other)
      self == other
    end
  end
end
