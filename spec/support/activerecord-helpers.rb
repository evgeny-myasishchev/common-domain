module ActiveRecordHelpers
  module ClassMethods
    def use_sqlite_activerecord_connection(database_name)
      before(:all) do
        logger = CommonDomain::Logger.factory.get('spec')
        @db_path = @tmp_root.join(database_name)
        logger.info("Establishing ActiveRecord sqlite3 connection. Database path: #{@db_path}")
        ActiveRecord::Base.establish_connection(
          adapter: "sqlite3",
          database: @db_path
        )
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