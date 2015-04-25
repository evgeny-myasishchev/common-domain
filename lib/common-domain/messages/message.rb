class CommonDomain::Messages::Message
  attr_reader :attribute_names
  
  def initialize(*args)
    @attribute_names = self.class.attribute_names
    if args.length == 1 && args[0].is_a?(Hash)
      hash = args[0]
      @attribute_names = self.class.attribute_names
      @attribute_names.each { |attr_name|
        set_attr_val attr_name, hash[attr_name] if hash.key?(attr_name)
      }
    else
      raise ArgumentError.new "Expected #{attribute_names.length} arguments: #{attribute_names.join(', ')}, got #{args.length}." if args.length != attribute_names.length
      args.each_index { |index|
        set_attr_val attribute_names[index], args[index]
      }
    end
  end
  
  private
    def set_attr_val attr_name, value
      instance_variable_set "@#{attr_name}", value
    end
  
  class << self
    def attribute_names
      @attribute_names ||= []
    end
    
    def attr_reader *args
      attribute_names.concat args
      super
    end
    
    def from_hash(hash)
      raise ArgumentError.new "Expected argument to be Hash, got: #{hash}" unless hash.is_a?(Hash)
      new(hash)
    end
  end
end