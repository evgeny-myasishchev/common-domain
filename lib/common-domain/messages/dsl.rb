module CommonDomain::Messages::DSL
  module ClassMethods
    def group(group_name, &block)
      group = Module.new do
        include CommonDomain::Messages::DSL
      end
      group.module_exec &block
      const_set(group_name, group)
    end
    
    def message(const_name, *args)
      event_class = Class.new(CommonDomain::Messages::Message) do
        attr_reader *args
      end
      const_set(const_name, event_class)
    end
  end
  
  def self.included(receiver)
    receiver.extend ClassMethods
  end
end