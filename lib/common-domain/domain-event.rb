module CommonDomain
  class DomainEvent
    attr_reader :aggregate_id
    attr_accessor :version
    def initialize(aggregate_id, attributes = {})
      @aggregate_id = aggregate_id
      @version      = 0
      @attribute_names = attributes.keys
      @attribute_names.each { |key| instance_variable_set("@#{key}", attributes[key]) }
    end
    
    def attribute(name)
      instance_variable_get "@#{name}"
    end
    
    def ==(other)
      aggregate_id == other.aggregate_id && 
      version == other.version &&
      @attribute_names.all? { |key| self.attribute(key) == other.attribute(key) }
    end
    
    def eql?(other)
      self == other
    end
    
    # DomainEvents DSL to simplify events definition.
    # Sample:
    # include CommonDomain::DomainEvent::DSL
    # event :AccountCreated, :login, :email
    #
    # Sample above is an equivalent to:
    # class AccountCreated < CommonDomain::DomainEvent
    #   attr_reader :login, :email
    #   
    #   def initialize(aggregate_id, login, email)
    #     super(aggregate_id, login: login, email: email)
    #   end
    # end
    module DSL
      module ClassMethods
        def events_group(group_name, &block)
          group = Module.new do
            include DSL
          end
          group.module_exec &block
          const_set(group_name, group)
        end
        
        def event(const_name, *args)
          event_class = Class.new(CommonDomain::DomainEvent) do
            attr_reader *args
            define_method :initialize do |aggregate_id, *values|
              attributes = {}
              args.each_index { |index|
                attributes[args[index]] = values[index]
              }
              super(aggregate_id, attributes)
            end
          end
          const_set(const_name, event_class)
        end
      end
      
      def self.included(receiver)
        receiver.extend ClassMethods
      end
    end
  end
end
