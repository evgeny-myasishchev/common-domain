class CommonDomain::Messages::Message
  def initialize(*args)
    if args.length == 1 && args[0].is_a?(Hash)
      hash = args[0]
      attribute_names.each { |attr_name|
        attr_key = attr_name
        attr_key = attr_key.to_s unless hash.key?(attr_key)
        raise ArgumentError.new "Value for the '#{attr_name}' attribute is missing." unless hash.key?(attr_key)
        set_attr_val attr_name, hash[attr_key]
      }
    else
      raise ArgumentError.new "Expected #{attribute_names.length} arguments: #{attribute_names.join(', ')}, got #{args.length}." if args.length != attribute_names.length
      args.each_index { |index|
        set_attr_val attribute_names[index], args[index]
      }
    end
  end
  
  def attribute_names
    self.class.attribute_names
  end
  
  def ==(other)
    self.class == other.class &&
      attribute_names.all? { |key| self.attribute(key) == other.attribute(key) }
  end

  def eql?(other)
    self == other
  end
  
  def attribute(name)
    instance_variable_get "@#{name}"
  end
  
  def to_s
    pure_class_name = self.class.name.split('::')[-1]
    output = "#{pure_class_name}"
    output << ' {'
    attribute_names.each { |name|
      output << name.to_s << ': ' << attribute(name)
      output << ', ' unless attribute_names.last == name
    }
    output << '}'
    output
  end
  
  def to_json(*args)
    attributes = {}
    attribute_names.each { |attr_name| attributes[attr_name] = attribute(attr_name) }
    {json_class: self.class, attributes: attributes}.to_json(*args)
  end
  
  def self.json_create(data)
    new(data['attributes'])
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