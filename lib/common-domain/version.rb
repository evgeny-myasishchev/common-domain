module CommonDomain
  MAJOR = 2
  MINOR = 0
  PATCH = 1
  BUILD = 'rc3'
  
  VERSION = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  
  def self.version
    VERSION
  end
end