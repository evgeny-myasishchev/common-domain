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
      dependencies = {}
      setup = BootstrapSetup.new
      setup.instance_eval &block
      setup.dependency_factories.each { |f| f.call(dependencies) }
      new dependencies
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