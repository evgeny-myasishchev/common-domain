if ENV.key?('CODECLIMATE_REPO_TOKEN')
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup'

gem 'rspec'
require 'rspec'
require 'sequel'
require 'event-store'
require 'common-domain'
require 'rspec/common-domain'
require 'log4r'

require 'log4r/yamlconfigurator'
require 'log4r/outputter/rollingfileoutputter'
log4r_config = YAML.load_file(File.expand_path('../support/log4r.yml', __FILE__))
file_outputter = log4r_config['log4r_config']["outputters"].detect { |outputter| outputter["type"] == "RollingFileOutputter" }
file_outputter["filename"] = File.join(File.dirname(__FILE__), file_outputter["filename"])
Log4r::YamlConfigurator.decode_yaml(log4r_config['log4r_config'])

CommonDomain::Logger.factory = CommonDomain::Logger::Log4rFactory.new

Dir[File.expand_path("../support/*.rb", __FILE__)].each { |helper| require helper }

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  
  config.before(:all) do
    @tmp_root = Pathname.new(File.expand_path(File.join('..', 'tmp'), __FILE__))
    @tmp_root.rmdir if @tmp_root.exist?
    @tmp_root.mkdir
  end
  
  module VerifyAndResetHelpers
    def verify(object)
      RSpec::Mocks.proxy_for(object).verify
    end

    def reset(object)
      RSpec::Mocks.proxy_for(object).reset
    end
  end
  
  config.include VerifyAndResetHelpers

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
