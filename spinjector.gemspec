Gem::Specification.new do |s|
  s.name        = 'spinjector'
  s.version     = '1.1.0'
  s.executables << 'spinjector'
  s.summary     = "Inject script phases into your Xcode project"
  s.description = ""
  s.authors     = ["Guillaume Berthier, Fabernovel"]
  s.email       = 'guillaume.berthier@fabernovel.com'
  # use `git ls-files -coz -x *.gem` for development
  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.homepage    = 'https://github.com/faberNovel/spinjector'
  s.license     = 'MIT'

  s.add_dependency 'optparse', '~> 0.1'
  s.add_dependency 'xcodeproj', '~> 1.21'
  s.add_dependency 'yaml', '~> 0.2'

  s.add_development_dependency 'bundler', '>= 1.12.0', '< 3.0.0'
  s.add_development_dependency 'rake', '~> 12.3'
  s.add_development_dependency 'minitest', '~> 5.11'
  s.add_development_dependency 'minitest-reporters', '~> 1.3'
  s.add_development_dependency 'minitest-hooks', '~> 1.5'
end
