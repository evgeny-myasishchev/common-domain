module SqlConnectionHelper
  def sqlite_memory_connection(logger_name = "common-domain::spec::orm")
    con = Sequel.connect adapter: "sqlite", database: ":memory:" 
    con.loggers << CommonDomain::Logger.get(logger_name)
    con
  end
end