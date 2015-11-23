require 'rubygems'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup'
require 'common-domain'
require 'event-store'

module SampleAppDepsWireup
  class SimpleDependencyWireup
    def call(deps)
      puts "Simple wireup: #{deps}"
      deps[:simple] = 'Simple dep'
    end
  end
  
  class EventStoreWireup
    def initialize(&block)
      puts "event-store-wireup: #{block}"
      @block = block
    end
    
    def call(deps)
      deps[:event_store] = EventStore.bootstrap do |with|
        @block.call with
      end
    end
    
    
  end
end

module CommonDomain::Wireup
  
  module ClassMethods
    def uses stage
      (@wireup_stages ||= []) << stage
    end
  
    def build(*args)
      deps = {}
      @wireup_stages.each { |stage| stage.call(deps) }
      new deps
    end
  end
  
  module InstanceMethods
    attr_reader :dependencies
    def initialize(dependencies)
      @dependencies = dependencies
      dependencies.each { |key, value|
        self.singleton_class.instance_exec(key) do
          attr_reader key
        end
        instance_variable_set "@#{key}", value
      }
    end
  end
  
  def self.included(receiver)
    receiver.extend ClassMethods
    receiver.send :include, InstanceMethods
  end
end

class SampleAppContext
  include CommonDomain::Wireup
  include SampleAppDepsWireup
  
  uses SimpleDependencyWireup.new
  uses EventStoreWireup.new { |with|
    with.in_memory_persistence
    with.synchronous_dispatcher do |commit|
      commit_context = CommonDomain::CommitContext.new commit
      commit.events.each { |event|
        event_bus.publish(event.body, context: commit_context)
      }
    end
  }
end

app_context = SampleAppContext.build
