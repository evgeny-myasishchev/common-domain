module SqlConnectionHelper
  include CommonDomain::Infrastructure::ConnectionSpecHelper
  
  def open_sequel_connection(logger_name = "common-domain::spec::orm")
    con = Sequel.connect make_sequel_friendly(RSpec.configuration.database_config), {:orm_log_level => :debug}
    con.loggers << CommonDomain::Logger.get(logger_name)
    con
  end
end