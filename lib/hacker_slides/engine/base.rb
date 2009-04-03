require 'rubygems'
require 'erb'
require 'fileutils'
require 'logger'

require 'hacker_slides/engine/content_helper'
require 'hacker_slides/engine/markup_engine'
require 'minitar'

module HackerSlides
  module Engine
    class Base

      include HackerSlides::ContentHelper

      attr_reader :presentation
      # attr_reader :logger

      def initialize
        @presentation = HackerSlides::Presentation.new
        # @logger = logger
      end

      #
      #
      def create_slides(input, bundle_name, output_dir)
        
        dirname = File.dirname(input)
        basename = File.basename(input, '.*')
        extname = File.extname(input)
        input_file =  File.expand_path("#{dirname}/#{basename}#{extname}")

        output_dir = File.expand_path(File.join(output_dir, basename))
        FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir) 

        bundle_path = lookup_bundle_path(bundle_name)

        manifest = load_manifest(bundle_path)
        
        content_with_metas = File.read(input_file)

        # read source document; split off optional header from source
        # strip leading optional headers (key/value pairs) including optional empty lines
        read_metas = true
        content = ''

        content_with_metas.each do |line|
          if read_metas && line =~ /^\s*(\w[\w-]*)[ \t]*:[ \t]*(.*)/
            name = $1.downcase
            value = $2.strip
            if(name == 'title')
              @presentation.title = value
            else
              @presentation.meta[name.to_sym] = value
            end
          elsif line =~ /^\s*$/
            content << line unless read_metas
          else
            read_metas = false
            content << line
          end
        end

        # ruby note: .*? is non-greedy (shortest-possible) regex match
        content.gsub!(/__SKIP__.*?__END__/m, '')
        content.sub!(/__END__.*/m, '')

        # you can use the meta
        content=ERB.new(content).result(binding)

        case markup_type(extname)
          when :textile
          markup_engine = HackerSlides::Engine::TextileMarkupEngine.new          
          when :markdown
          markup_engine = HackerSlides::Engine::MarkdownMarkupEngine.new
          else
          puts "#{extname.inspect} doesn't support util now"
          end
        
        content = markup_engine.to_html(content) if(markup_engine)

        # implement in 
        slides = post_processing(content)

        start_here = nil
        static_files = []

        # copy manifest files
        manifest.each do |file|
          if(File.extname(file) == '.erb')
            template_file = File.basename(file)
            if(template_file == 'template.html.erb')
              outname = 'index.html'
              start_here = with_output_path(outname, output_dir)
            else
              outname = File.basename(file, '.*')
            end
            File.open(with_output_path(outname, output_dir), "w+") do |out|
              Zlib::GzipReader.open(bundle_path) do |tgz|
                Archive::Tar::Minitar::Input.open(tgz) do |stream|
                  stream.each { |entry| out.puts render_erb_template(entry.read, binding) if(entry.full_name == file )}
                end
              end
            end
          else
            static_files << file
          end

          extract_file_from_bundle(bundle_path, static_files, output_dir)
        end

        puts 'slides generation done.'
        puts "start here: #{start_here}" if start_here
        puts 

        return start_here
      end
      
      def list_bundles
        puts 
        puts 'User bundles:'
        puts '  none'
        puts 
        puts 'Built-in bundles:'
        Dir.glob(File.join(builtin_bundle_dir, '*')).each do |bundle|
          bundle_name = bundle.split('/').last
          name = bundle_name #.split('.')[0..-2].join('.')
          puts "  * #{name}"
        end
        puts 
      end

      def load_manifest(bundle)
        Zlib::GzipReader.open(bundle) do |tgz|
          Archive::Tar::Minitar::Input.open(tgz) do |stream|
            stream.each do |entry|
              if(entry.name == 'MANIFEST')
                manifest = []
                entry.read.split(/\n/).each_with_index do |line,i|
                  case line
                  when /^\s*$/
                    # skip empty lines
                  when /^\s*#.*$/
                    # skip comment lines
                  else       
                    manifest << line.strip
                  end
                end
                return manifest
              end
            end
          end
        end
        return nil
      end


      def extract_file_from_bundle(bundle, files, dest)
        Zlib::GzipReader.open(bundle) do |tgz|
          Archive::Tar::Minitar.unpack(tgz, dest, files)
        end
      end

      def markup_type(extname)
        if(HackerSlides::Engine::TextileMarkupEngine.support_extnames.include?(extname))
          return :textile
        end

        if(HackerSlides::Engine::MarkdownMarkupEngine.support_extnames.include?(extname))
          return :markdown
        end
        
      end

      def post_processing(content)
        # do nothing
      end

      def with_output_path(output_file, output_dir)
        return File.expand_path(File.join(output_dir, output_file))
      end

      def render_erb_template(content, the_binding)
        ERB.new(content).result(the_binding)
      end
      
      def lookup_bundle_path(bundle_name)
        return File.join(builtin_bundle_dir, "#{bundle_name}.bundle")
      end

      def builtin_bundle_dir
        return File.expand_path(File.dirname(__FILE__) + '/../../../bundles')
      end

    end
  end
end
