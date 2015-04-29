module CommonDomain::Messages::DSL
  module ClassMethods
    def group(group_name, &block)
      dsl_module = @dsl_module || CommonDomain::Messages::DSL
      group = Module.new do
        include dsl_module
      end
      group.module_exec &block
      const_set(group_name, group)
    end
    
    def message(const_name, *args, &block)
      message_class = Class.new(@message_base_class || CommonDomain::Messages::Message) do
        attr_reader *args
      end
      message_class.class_eval &block if block_given?
      const_set(const_name, message_class)
    end
    
    def setup_dsl options
      @message_base_class = options[:message_base_class]
      @dsl_module = options[:dsl_module]
    end
  end
  
  def self.included(receiver)
    receiver.extend ClassMethods
  end
end
