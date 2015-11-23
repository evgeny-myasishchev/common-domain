class CommonDomain::ApplicationContext
  def initialize(dependencies)
    dependencies.each { |key, value|
      self.singleton_class.instance_exec(key) do
        attr_reader key
      end
      instance_variable_set "@#{key}", value
    }
  end
  
  class << self
    def bootstrap(&block)
      deps = {}
      dep_factories = []
      setup = Class.new
      setup.instance_exec(dep_factories) do |dep_factories|
        @dep_factories = dep_factories
        def with dependency_factory
          @dep_factories << dependency_factory
        end
      end
      setup.instance_eval &block
      dep_factories.each { |f| f.call(deps) }
      new deps
    end
  end
  
  class BootstrapSetup
    attr_reader :dependency_factories
    def initialize
      @dependency_factories = []
    end
    def with dependency_factory
      @dependency_factories << dependency_factory
    end
  end
end