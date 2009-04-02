require 'rubygems'
require 'RedCloth'

module HackerSlides
  module Engine
    class MarkupEngine

      def to_html(content)
        raise NotImplementedError, 'implmenent the method in subclass'
      end
    end

    class TextileMarkupEngine < MarkupEngine
      def self.support_extnames
        ['.textile', '.t']
      end

      def to_html(content)
        # turn off hard line breaks
        # turn off span caps (see http://rubybook.ca/2008/08/16/redcloth)
        red = RedCloth.new(content, [:no_span_caps])
        red.hard_breaks = false
        return red.to_html
      end
    end

    class MarkdownMarkupEngine < MarkupEngine
      def self.support_extnames
        ['.markdown', '.m', '.mark', '.mkdn', '.md', '.txt', '.text']
      end

      def to_html(content)
      end
    end
  end
end
