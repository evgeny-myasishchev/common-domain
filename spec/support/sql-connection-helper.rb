module SqlConnectionHelper
  def sqlite_memory_connection(logger_name = "common-domain::spec::orm")
    con = Sequel.connect RSpec.configuration.database_config, {:orm_log_level => :debug}
    con.loggers << CommonDomain::Logger.get(logger_name)
    con
  end
end