module HackerSlides
  module ContentHelper

    def slide_metadata
      metadata_str = ''
      metadata_str << "<title>#{@presentation.title}</title>\n"
      metadata_str << "<!-- metadata -->\n"
      metadata_str << "<meta name=\"author\" content=\"#{@presentation.author}\" />\n"

      @presentation.meta.each do |name, value|
        metadata_str << "<meta name=\"#{name}\" content=\"#{value}\" />\n"
      end
      metadata_str << "<meta name=\"generator\" content=\"HackerSlides\" />"

      return metadata_str
    end

    def slide_footer
     footer = <<EOF 
<h1>#{@presentation.title}</h1>
<h2>Time: 
<script type="text/javascript">
<!--
var currentTime = new Date()
var hours = currentTime.getHours()
var minutes = currentTime.getMinutes()
if (minutes < 10){
minutes = "0" + minutes
}
document.write(hours + ":" + minutes + " ")
if(hours > 11){
document.write("PM")
} else {
document.write("AM")
}
//-->
</script>
</h2>
EOF
      return footer
    end
  end
end
