module HackerSlides
  class Presentation

    attr_accessor :title
    attr_writer :author
    attr_writer :version
    attr_reader :created_at
    attr_reader :meta
    attr_reader :total_slides

    def initialize
      @title = 'Untitled Presentation'
      @meta = Hash.new
      @meta[:created_at] = Time.now
      @total_slides = 0
    end

    def author
      return @meta[:author]
    end

    def version
      return @meta[:version]
    end

    def created_at
      return @meta[:created_at]
    end

    def incr_slides
      @total_slides = @total_slides + 1
    end

  end
end
