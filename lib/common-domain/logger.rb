module CommonDomain
  class Logger
    class << self
      def get(name)
        Log4r::Logger[name] || Log4r::Logger.new(name)
      end
    end
  end
end
