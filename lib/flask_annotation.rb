require 'fileutils'
require 'json'

require_relative 'tei_annotation'

class FlaskAnnotation
  attr_reader :id
  attr_reader :anno_ref_id
  attr_reader :duplicate
  attr_reader :letter_id
  attr_reader :publishable
  attr_reader :quote
  attr_reader :raw_res
  attr_reader :tags
  attr_reader :text
  attr_reader :xpath
  attr_reader :xml

  attr_accessor :char_start
  attr_accessor :char_end

  def initialize(flask_res)
    @raw_res = JSON.parse(JSON.generate(flask_res))

    @id = flask_res["id"]
    if flask_res["anno_ref_id"] && flask_res["anno_ref_id"].length > 0
      @anno_ref_id = flask_res["anno_ref_id"]
      @duplicate = true
    else
      # use traditional id if it is not referring to a different annotation
      @anno_ref_id = flask_res["id"]
      @duplicate = false
    end
    @letter_id = flask_res["pageID"]
    @quote = flask_res["quote"]
    @tags = flask_res["tags"]
    @text = flask_res["text"]

    @publishable = should_publish?
    @xpath = prep_xpath(flask_res["ranges"])
    @char_start = flask_res["ranges"][0]["startOffset"].to_i
    @char_end = flask_res["ranges"][0]["endOffset"].to_i

    @xml = create_annotation_xml
  end

  private

  def create_annotation_xml
    if @text && !@duplicate
      note = %{<note type='annotation' xml:id='a#{@id}' target='#{@id}' corresp='cat.#{@letter_id}'>#{@text}</note>}
      anno = TeiAnnotation.new(note)
      @xml = anno.tei
    else
      @xml = nil
    end
  end

  def prep_xpath(ranges)
    xpath = ranges[0]["start"]
    # chop the beginning off until "tei[1]"
    xpath.sub!(/.*\/tei\[1\]/, "")
    xpath = tei_casing(xpath)
    # add ns also double slashes to overcome boilerplate extra elements
    # TODO this will be a problem if boilerplate REMOVES elements
    xpath.gsub!(/\//, "//tei:")
    return "//tei:TEI#{xpath}"
  end

  def should_publish?
    # checks against the config file for publishable statuses
    return @tags.all? { |tag| $allowed_statuses.include?(tag) }
  end

  def tei_casing(xpath)
    $tei_cases.each do |element|
      xpath.gsub!(element.downcase, element)
    end
    return xpath
  end
end
