require File.expand_path(File.join('..', 'lib', 'common-domain', 'version'), __FILE__)

Gem::Specification.new do |s|
  s.name        = 'common-domain'
  s.version     = CommonDomain.version
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Evgeny Myasishchev']
  s.email       = ['evgeny.myasishchev@gmail.com']
  s.summary     = "DDD building blocks."
  s.description = "Various concerns to build domain model and related infrastructure around it. Inspired by https://github.com/joliver/CommonDomain."
  s.homepage    = 'https://github.com/evgeny-myasishchev/common-domain'
  s.files       = Dir["lib/**/*"]
  s.test_files  = Dir['spec/**/*']
  
  s.add_dependency 'event-store', '~> 1.0'
  
  s.add_development_dependency 'log4r'
  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'activerecord'
end
