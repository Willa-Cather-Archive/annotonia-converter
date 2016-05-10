class FlaskAnnotation
  attr_reader :id
  attr_reader :letter_id
  attr_reader :quote
  attr_reader :text
  attr_reader :xpath
  attr_reader :xml

  attr_accessor :char_start
  attr_accessor :char_end

  def initialize(flask_res)
    @id = flask_res["id"]
    @letter_id = flask_res["letterID"]
    @quote = flask_res["quote"]
    @text = flask_res["text"]

    @xpath = prep_xpath(flask_res["ranges"])
    @char_start = flask_res["ranges"][0]["startOffset"].to_i
    @char_end = flask_res["ranges"][0]["endOffset"].to_i

    @xml = create_annotation_xml
  end

  def write_annotation_xml
    File.open("#{$annotation_file}", "a") { |f| f.puts(@xml) }
  end
  
  private

  def create_annotation_xml
    if @text
      @xml = %{
        <note type='annotation' xml:id='#{@id}' target='#{@id}'>
          #{@text}
        </note>
      }
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

  def tei_casing(xpath)
    $tei_cases.each do |element|
      xpath.gsub!(element.downcase, element)
    end
    return xpath
  end
end