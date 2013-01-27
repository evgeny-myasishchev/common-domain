require "bundler/gem_tasks"
require 'rspec/core/configuration_options'
require 'rspec/core/option_parser'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new do |t|
  options   = RSpec::Core::ConfigurationOptions.new([]).parse_options
  t.pattern = options[:pattern]
end