module CommonDomain
  class Logger
    
    #Lasy logger is used to delay real logger retrieval untill it's really needs to be used
    #This helps to have configured logger even if libs that are using the logger are required before
    #the logger is configured.
    class LasyLogger
      def initialize(name, factory)
        @name = name
        @factory = factory
      end
    
      def debug(message)
        logger.debug(message)
      end
    
      def info(message)
        logger.info(message)
      end
    
      def warn(message)
        logger.warn(message)
      end
    
      def error(message)
        logger.error(message)
      end
    
      def fatal(message)
        logger.fatal(message)
      end
      
      private
        def logger
          @logger ||= @factory.get(@name)
        end
    end
    
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
        LasyLogger.new name, factory
      end
      
      def factory
        @factory ||= DefaultFactory.new
      end
    end
  end
end
