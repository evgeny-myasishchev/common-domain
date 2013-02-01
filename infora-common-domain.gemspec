Gem::Specification.new do |s|
  s.name        = 'infora-common-domain'
  s.version     = '0.0.2a'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Evgeny Myasishchev', 'Vladimir Ikryanov']
  s.email       = ['info@infora.com.ua']
  s.summary     = "Common DDD building blocks."
  s.description = "Common DDD building blocks. Inspired by https://github.com/joliver/CommonDomain."
  s.homepage    = 'http://infora.com.ua'
  s.files       = Dir["lib/**/*"]
  s.test_files  = Dir['spec/**/*']
  
  s.add_dependency 'infora-event-store', '>= 0.0.2a'
  
  s.add_development_dependency 'log4r'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sqlite3'
end
