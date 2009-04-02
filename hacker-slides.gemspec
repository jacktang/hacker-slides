require File.dirname(__FILE__) + '/lib/hacker_slides/version'

spec = Gem::Specification.new do |s|
  s.name = 'hacker-slides'
  s.version = HackerSlides::Version.value
  s.date = '2009-04-01'
  s.summary = 'Slides Only For Hackers'
  s.description = s.summary
  s.email = 'himars@gmail.com'
  s.homepage = "http://github.com/jacktang/hacker-slides"
  s.has_rdoc = true
  s.authors = ["Jack Tang"]
  s.add_dependency('RedCloth', '>= 4.1.9') 
  #s.add_dependency('sqlite3-ruby', '>=1.2.4')

  s.require_path = 'lib'
  s.executables = ['hacker-slides', 'hslides']

  # ruby -rpp -e' pp `git ls-files`.split("\n") '
  s.files = Dir['lib/**/*.rb'] + Dir['spec/**/*.rb'] + ["LICENSE", "README.textile"]
end
