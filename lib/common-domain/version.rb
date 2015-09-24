module CommonDomain
  MAJOR = 3
  MINOR = 0
  PATCH = 1
  BUILD = 'rc1'
  
  VERSION = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  
  def self.version
    VERSION
  end
end