#require File.dirname(__FILE__) + '/lib/hacker_slides/version'

module HackerSlides
  class Version
    MAIN  = 1; MAJOR = 0; MINOR = 1
    class << self
      def value
        return "#{MAIN}.#{MAJOR}.#{MINOR}"
      end
    end
  end
end


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
  s.add_dependency('BlueCloth', '>=1.0.0')
  s.add_dependency('highline', '>=1.5.0')

  s.require_path = 'lib'
  s.executables = ['hacker-slides']

  # ruby -rpp -e' pp `git ls-files`.split("\n") '
  #s.files = Dir['bundles/*.bundle'] + Dir['samples/sample.*'] + Dir['lib/**/*.rb'] + Dir['spec/**/*.rb'] + ["LICENSE", "README.textile"]
  s.files = [ 
              'samples/sample.textile',
              'samples/sample.markdown',
              'bundles/s5-simple.bundle',
              'lib/hacker_slides.rb',
              'lib/hacker_slides/bundle.rb',
              'lib/hacker_slides/presentation.rb',
              'lib/hacker_slides/version.rb',
              'lib/hacker_slides/engine.rb',
              'lib/hacker_slides/engine/base.rb',
              'lib/hacker_slides/engine/markup_engine.rb',
              'lib/hacker_slides/engine/render_engine.rb',
              'lib/hacker_slides/engine/s5_slides_generator.rb',
              'lib/hacker_slides/engine/slides_engine.rb',
              'lib/hacker_slides/helper.rb',
              'lib/hacker_slides/helper/content_helper.rb', 
              'lib/minitar.rb',
              'lib/minitar/posix_header.rb',
              'lib/minitar/input.rb',
              'lib/minitar/output.rb',
              'lib/minitar/reader.rb',
              'lib/minitar/writer.rb',
              'LICENSE',
              'README.textile'
            ]
end
