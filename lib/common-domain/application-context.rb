class CommonDomain::ApplicationContext
  def initialize(dependencies)
    dependencies.each { |key, value|
      self.singleton_class.instance_exec(key) do
        attr_reader key
      end
      instance_variable_set "@#{key}", value
    }
  end
end