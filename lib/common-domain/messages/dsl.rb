module CommonDomain::Messages::Dsl
  module ClassMethods
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