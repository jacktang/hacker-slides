module HackerSlides
  module Engine
    class Base
      attr_reader :metadata

      def create_slides
        hacker_slides =  ''
        content_with_metas = File.read(hacker_slides)

        # read source document; split off optional header from source
        # strip leading optional headers (key/value pairs) including optional empty lines
        read_metas = true
        content = ""

        content_with_metas.each do |line|
          if read_metas && line =~ /^\s*(\w[\w-]*)[ \t]*:[ \t]*(.*)/
            name = $1.downcase
            value = $2.strip
            
            @metadata.put(name, value)
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

        content=ERB.new(content).result(binding)

        content = case @markup_type
                  when :markdown
                    markdown_to_html( content )
                  when :textile
                    textile_to_html( content )
                  end 
        
        # create s5 slides

        # wrap h1's in slide divs; note use just <h1 since some processors add ids e.g. <h1 id='x'>
        content.each_line do |line|
          if line.include?( '<h1' ) then
            content2 << "\n\n</div>" if slide_counter > 0
            content2 << "<div class='slide'>\n\n"
            slide_counter += 1
          end
          content2 << line
        end
        content2 << "\n\n</div>" if slide_counter > 0

      end

      def render_erb_template(content, the_binding)
        ERB.new(content).result(the_binding)
      end
      
      def load_manifest

      end

      def cache_dir
        PLATFORM =~ /win32/ ? win32_cache_dir : File.join(File.expand_path("~"), ".hackerslides")
      end
      
      def win32_cache_dir
        unless File.exists?(home = ENV['HOMEDRIVE'] + ENV['HOMEPATH'])
          puts "No HOMEDRIVE or HOMEPATH environment variable. Set one to save a local cache of stylesheets for syntax highlighting and more."
          return false
        else
          return File.join(home, '.hackerslides')
        end
      end

    end
  end
end
