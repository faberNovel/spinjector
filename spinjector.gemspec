Gem::Specification.new do |s|
  s.name        = 'spinjector'
  s.version     = '0.0.2'
  s.executables << 'spinjector'
  s.summary     = "Inject script phases into your Xcode project"
  s.description = ""
  s.authors     = ["Guillaume Berthier, Fabernovel"]
  s.email       = 'guillaume.berthier@fabernovel.com'
  # use `git ls-files -coz -x *.gem` for development
  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.homepage    = 'https://www.fabernovel.com'
  s.license     = 'MIT'
end