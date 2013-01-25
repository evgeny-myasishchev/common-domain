module CommonDomain
  class Logger
    #Uses default ruby logger and writes to STDOUT
    class DefaultFactory
      def get(name)
        require 'logger'
        logger = ::Logger.new(STDOUT)
        logger.formatter = proc do |severity, datetime, progname, msg|
          "[#{datetime} #{name} #{severity}]: #{msg}\n"
        end
        logger
      end
    end
    
    class Log4rFactory
      def get(name)
        Log4r::Logger[name] || Log4r::Logger.new(name)
      end
    end
    
    class << self
      attr_writer :factory
      
      def get(name)
        factory.get name
      end
      
      def factory
        @factory ||= DefaultFactory.new
      end
    end
  end
end
