Gem::Specification.new do |s|
  s.name        = 'rails_use_case'
  s.version     = '0.0.10'
  s.date        = '2021-10-04'
  s.summary     = 'Rails UseCase and Service classes'
  s.description = s.summary
  s.authors     = ['Benjamin Klein']
  s.email       = ['bk@itws.de']
  s.homepage    = 'https://github.com/phortx/rails-use-case'
  s.license     = 'MIT'

  s.files = Dir['lib/**/*', 'README.md']

  s.add_dependency 'activemodel', '>= 6.1.3'
  s.add_dependency 'railties', '>= 6.1.3'

  s.add_development_dependency 'bundler-audit', '~> 0.6'
  s.add_development_dependency 'fakefs', '~> 1.2.0'
  s.add_development_dependency 'pry', '~> 0.13.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.9'
  s.add_development_dependency 'rspec-mocks', '~> 3.9'
  s.add_development_dependency 'rubocop', '~> 0.78'
  s.add_development_dependency 'rubocop-rspec', '~> 1.37'
  s.add_development_dependency 'rubygems-tasks'
  s.add_development_dependency 'simplecov', '~> 0.17'
end
