module CommonDomain
  MAJOR = 1
  MINOR = 0
  TINY = 2
  PRE = "a"
  
  VERSION = [MAJOR, MINOR, TINY, PRE].join('.')
  
  def self.version
    VERSION
  end
end