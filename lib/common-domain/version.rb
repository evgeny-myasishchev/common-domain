module CommonDomain
  MAJOR = 3
  MINOR = 1
  PATCH = 0
  BUILD = 'b1'
  
  VERSION = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  
  def self.version
    VERSION
  end
end