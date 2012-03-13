Gem::Specification.new do |s|
  s.platform          = Gem::Platform::RUBY
  s.name              = 'refinerycms-elements'
  s.version           = '0.1.0'
  s.description       = 'Elements engine for Refinery CMS'
  s.date              = '2011-08-19'
  s.summary           = 'Elements engine for Refinery CMS'
  s.authors           = ['Alexander Jentz']
  s.license           = %q{MIT}
  s.require_paths     = %w(lib)
  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- spec/*`.split("\n")
  s.add_dependency    'apotomo',  '1.2.1'
  s.add_dependency    'acts_as_list',  '~>0.1.4'
end
