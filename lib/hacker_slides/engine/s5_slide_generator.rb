module HackerSlides
  module Engine
    class S5SlideGenerator
      def textile_to_html(content)
        # turn off hard line breaks
        # turn off span caps (see http://rubybook.ca/2008/08/16/redcloth)
        red = RedCloth.new(content, [:no_span_caps])
        red.hard_breaks = false
        content = red.to_html
      end
    end
  end
end
