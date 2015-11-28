module CommonDomain
  module Loggable
    def self.included(receiver)
      receiver.class_eval do
        define_method :logger do
          @logger ||= CommonDomain::Logger.get(self.class.name || receiver.name)
        end
        private :logger
      end
    end
  end
  
  class Logger
    extend Forwardable
    
    Levels = [:debug, :info, :warn, :error, :fatal]
    
    def_delegators :target_logger, :level, :level=, :formatter
    Levels.each { |level| def_delegators :target_logger, level, "#{level}?".to_sym }
    
    def initialize(name)
      @name = name
    end
    
    private def target_logger
      self.class.factory.get(@name)
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
      
      def factory
        @factory ||= DefaultFactory.new
      end
      
      def get(name)
        Logger.new name
      end
    end
  end
end
