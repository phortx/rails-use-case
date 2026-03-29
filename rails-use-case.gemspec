Gem::Specification.new do |s|
  s.name        = 'rails_use_case'
  s.version     = '0.1.0'
  s.summary     = 'Rails UseCase and Service classes'
  s.description = s.summary
  s.authors     = ['Benjamin Klein']
  s.email       = ['bk@itws.de']
  s.homepage    = 'https://github.com/phortx/rails-use-case'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.0'

  s.files = Dir['lib/**/*', 'README.md']

  s.add_dependency 'activemodel', '>= 7.0'

  s.add_development_dependency 'bundler-audit', '~> 0.9'
  s.add_development_dependency 'fakefs', '~> 2.0'
  s.add_development_dependency 'pry', '~> 0.14'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.13'
  s.add_development_dependency 'rspec-mocks', '~> 3.13'
  s.add_development_dependency 'rubocop', '~> 1.65'
  s.add_development_dependency 'rubocop-rspec', '~> 3.3'
  s.add_development_dependency 'simplecov', '~> 0.22'
end
