require 'rubygems'
require 'erb'
require 'fileutils'
require 'highline/import'

require 'hacker_slides/bundle'
require 'hacker_slides/helper'
require 'hacker_slides/engine/base'
require 'hacker_slides/engine/markup_engine'

module HackerSlides
  class SlidesEngine < Engine::Base
    include HackerSlides::ContentHelper

    attr_reader :presentation

    # Create one SlidesEngine instance 
    #
    def initialize
      @presentation = HackerSlides::Presentation.new
    end


    # 
    #
    def create_slides(input, bundle_name, output_dir)

      dirname = File.dirname(input)
      basename = File.basename(input, '.*')
      extname = File.extname(input)

      input_file = File.expand_path(input)
      if(not File.exist?(input_file))
        if(agree("Could you like to create the presentation from sketch [yn] "))
          sketch_slides(input_file)
          puts "generate #{input_file} from sketch"
          return
        end
      end

      output_dir = File.expand_path(File.join(output_dir, basename))
      FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir) 

      bundle_path = HackerSlides::Bundle.lookup_bundle_path(bundle_name)

      manifest = HackerSlides::Bundle.load_manifest(bundle_path)
      
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
      content = ERB.new(content).result(binding)

      case markup_type(extname)
      when :textile
        markup_engine = HackerSlides::TextileMarkupEngine.new          
      when :markdown
        markup_engine = HackerSlides::MarkdownMarkupEngine.new
      else
        puts "only textile and markdown markup supported"
        puts "#{extname.inspect} doesn't support util now."
      end
      
      content = markup_engine.to_html(content) if(markup_engine)

      # implement in 
      slides = post_processing(content) if defined?(:post_processing)

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

        HackerSlides::Bundle.extract_files_from_bundle(bundle_path, static_files, output_dir)
      end

      return start_here
    end

    def sketch_slides(input_file)
      extname = File.extname(input_file)
      case markup_type(extname)
      when :textile
        sample_file = File.join(File.dirname(__FILE__) + '/../../../samples/sample.textile')
      when :markdown
        sample_file = File.join(File.dirname(__FILE__) + '/../../../samples/sample.markdown') 
      else
        puts "only textile and markdown markup supported"
        puts "#{extname.inspect} doesn't support util now."        
      end
      FileUtils.cp(sample_file, input_file)
    end

    def markup_type(extname)
      if(HackerSlides::TextileMarkupEngine.support_extnames.include?(extname))
        return :textile
      end

      if(HackerSlides::MarkdownMarkupEngine.support_extnames.include?(extname))
        return :markdown
      end
    end

    def with_output_path(output_file, output_dir)
      return File.expand_path(File.join(output_dir, output_file))
    end

    def render_erb_template(content, the_binding)
      ERB.new(content).result(the_binding)
    end

  end
end
