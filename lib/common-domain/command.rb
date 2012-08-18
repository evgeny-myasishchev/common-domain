module CommonDomain
  class CommandClassMissingError < ::StandardError
    def initialize
      super("Can not determine command class because class_name parameter not found.")
    end
  end

  class Command
    attr_reader :aggregate_id

    def initialize(aggregate_id, attributes = {})
      @aggregate_id = aggregate_id
      attributes.each_key { |key| instance_variable_set("@#{key}", attributes[key]) }
    end

    class << self
      #
      # Reconstructs the command from hash. The hash should include at least one parameter "class_name".
      # The param should be a full name of the command class so Kernel.const_get(classname) could recognize it.
      # All the other params are passed directly to the attributes so they'll be assigned automatically.
      #
      def from_hash(hash)
        hash = hash.dup
        raise CommandClassMissingError.new unless hash.key?(:class_name)
        klass = constantize(hash.delete(:class_name))
        aggregate_id = hash.delete(:aggregate_id)
        klass.new aggregate_id, hash
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
  end
end