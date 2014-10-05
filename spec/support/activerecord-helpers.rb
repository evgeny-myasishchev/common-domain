module ActiveRecordHelpers
  module ClassMethods
    def establish_activerecord_connection
      before(:all) do
        logger = CommonDomain::Logger.factory.get('spec')
        connection_spec = RSpec.configuration.database_config
        logger.info("Establishing ActiveRecord connection. Connection spec: #{connection_spec}")
        ActiveRecord::Base.establish_connection(connection_spec)
      end
  
      after(:all) do
        ActiveRecord::Base.remove_connection
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend ClassMethods
  end
end