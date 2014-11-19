module CommonDomain
  class CommandClassMissingError < ::StandardError
    def initialize
      super("Can not determine command class because class_name parameter not found.")
    end
  end

  class Command
    attr_reader :aggregate_id, :attribute_names, :headers

    def initialize(aggregate_id_or_params = nil, params = {})
      aggregate_id = nil
      if aggregate_id_or_params.is_a?(Hash)
        params = aggregate_id_or_params
        aggregate_id = params.delete(:aggregate_id)
      else
        aggregate_id = aggregate_id_or_params
      end
      @aggregate_id = aggregate_id
      @headers = params.delete(:headers) || {}
      attributes = params.delete(:attributes) || params
      attributes.each_key { |key| instance_variable_set("@#{key}", attributes[key]) }
      @attribute_names = attributes.keys
    end
    
    def attribute(name)
      instance_variable_get "@#{name}"
    end
    
    def ==(other)
      aggregate_id == other.aggregate_id &&
      self.class == other.class &&
      @attribute_names.all? { |key| self.attribute(key) == other.attribute(key) } &&
      headers.all? { |key, value| value == other.headers[key] }
    end

    def eql?(other)
      self == other
    end
    
    def to_s
      output = "#{self.class.name}"
      output << '{'
      output << 'attributes: {'
      @attribute_names.each { |name|
        output << name.to_s << ':' << '"' << attribute(name) << '"'
        output << ', ' unless @attribute_names.last == name
      }
      output << '}'
      output << '}'
      output
    end

    class << self
      #
      # Reconstructs the command from hash. The hash should include at least one parameter "class_name".
      # The param should be a full name of the command class so Kernel.const_get(classname) could recognize it.
      # All the other params are passed directly to the attributes so they'll be assigned automatically.
      #
      def from_hash(hash)
        hash = hash.dup
        klass = nil
        if self != Command
          klass = self
        elsif hash.key?(:class_name)
          klass = constantize(hash[:class_name])
        else
          raise CommandClassMissingError.new
        end
        klass.new hash
      end

      private
        # Taken form ActiveSupport:
        # File activesupport/lib/active_support/inflector/methods.rb, line 213
        def constantize(camel_cased_word)
          names = camel_cased_word.split('::')
          names.shift if names.empty? || names.first.empty?

          constant = Object
          names.each do |name|
            constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
          end
          constant
        end
    end
  
    # Commands DSL to simplify commands definition.
    # Sample:
    # include CommonDomain::Command::DSL
    # command :CreateAccount, :login, :email
    #
    # Sample above is an equivalent to:
    # class CreateAccount < CommonDomain::Command
    #   attr_reader :login, :email
    # end
    module DSL
      module ClassMethods
        def commands_group(group_name, &block)
          group = Module.new do
            include DSL
          end
          group.module_exec &block
          const_set(group_name, group)
        end
        
        def command(const_name, *args, &block)
          command_class = Class.new(CommonDomain::Command) do
            attr_reader *args
            define_method :initialize do |*args|
              super(*args)
            end
          end
          command_class.class_eval &block if block_given?
          const_set(const_name, command_class)
        end

      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
      end
    end
  end
end