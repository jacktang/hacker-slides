module HackerSlides
  module S5SlidesGenerator

    def post_processing(content)
      # create s5 slides
      slide_counter = 0
      result = ''

      company = @presentation.meta[:company]
      website = @presentation.meta[:website]

      preface = "<div class=\"slide\">\n"
      preface << "<h1>#{@presentation.title}</h1>\n"
      preface << "<h3>#{@presentation.author}</h3>\n"
      preface << "<h4><a href=\"#{website}\">#{company}</a></h4>" if(company)
      preface << "</div>"

      result << preface

      # wrap h1's in slide divs; note use just <h1 since some processors add ids e.g. <h1 id='x'>
      content.each_line do |line|
        if line.include?( '<h1' ) then
          result << "\n\n</div>" if slide_counter > 0
          result << "<div class='slide'>\n"
          slide_counter += 1
        end
        result << line
      end
      result << "\n</div>" if slide_counter > 0
      return result
    end
  end
end
