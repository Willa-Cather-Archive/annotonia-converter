require 'nokogiri'
require 'htmlentities'

class TeiAnnotation
  attr_reader :html
  attr_accessor :tei

  def initialize(note)
    decoded = HTMLEntities.new.decode(note)
    @html = Nokogiri::XML(decoded, &:noblanks)
    teify
  end

  def teify
    @tei = @html
    replace_one_to_one("br", "<lb>")
    replace_open_close("i", "<hi rend='italic'>", "</hi>")
    replace_open_close("em", "<hi rend='italic'>", "</hi>")
    replace_open_close("blockquote", "<q rend='block'>", "</q>")
    # underlined text
    replace_open_close("span[style='text-decoration: underline;']", "<hi rend='underline'>", "</hi>")
    # lists
    replace_open_close("ul", "<list>", "</list>")
    replace_open_close("ol", "<list rend='numbered'>", "</list>")
    replace_open_close("li", "<item>", "</item>")
    # links
    links = @tei.css "a[href]"
    links.each do |link|
      link.replace("<ref type='url' target='#{link.attribute("href")}'>#{link.inner_html}</ref>")
    end
    # images
    imgs = @tei.css "img"
    imgs.each do |img|
      img.replace("<figure corresp='#{img.attribute("src")}'><figDesc>#{img.attribute("alt")}</figDesc></figure>")
    end
    # video
    vids = @tei.css "video"
    vids.each do |vid|
      source1 = vid.at_css "source"
      # TODO what to do with backup source?
      # TODO what about video description?
      vid.replace("<media mimeType='video/mp4' url='#{source1.attribute("src")}' width='#{vid.attribute("width")}'/>")
    end
  end

  private

  def replace_one_to_one(old_tag, new_tag)
    elements = @tei.css old_tag
    elements.each do |ele|
      ele.replace(new_tag)
    end
  end

  def replace_open_close(old_tag, new_tag_open, new_tag_close)
    elements = @tei.css old_tag
    elements.each do |ele|
      ele.replace("#{new_tag_open}#{ele.inner_html}#{new_tag_close}")
    end
  end

end
