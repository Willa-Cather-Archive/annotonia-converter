class Letter
  attr_reader :id
  attr_reader :cat_id
  attr_reader :file_read
  attr_reader :file_write

  attr_accessor :xml
  attr_accessor :warnings
  attr_accessor :errors

  def initialize(path)
    @file_read = path
    @id = derive_id(path)
    @cat_id = "cat.let#{@id}"
    @file_write = "#{$letters_out}/#{@cat_id}.xml"
    @xml = read_xml(path)
    @warnings = []
    @errors = []
  end

  def add_ref(annotation)
    element = @xml.at_xpath(annotation.xpath, "tei" => $tei_ns)
    if element
      range = (annotation.char_start..annotation.char_end)
      highlight = element.inner_html[range]
      if highlight.strip == annotation.quote.strip
        new_content = insert_ref(element.inner_html, annotation)
        if new_content && new_content.class == String
          element.inner_html = new_content
        else
          @errors << "Unable to add #{annotation.id} ref to #{@cat_id}: #{annotation.quote}"
        end
      else
        @warnings << %{Check file #{@cat_id}.xml for #{annotation.id} ('#{annotation.quote}') placement. xpath: annotation.xpath\n }
        annotation.char_start = element.inner_html.index(annotation.quote)
        annotation.char_end = annotation.quote.length + annotation.char_start
        new_content = insert_ref(element.inner_html, annotation)
        element.inner_html = new_content
      end
    else
      @errors << "No element found at xpath #{annotation.xpath} for #{cat_id}.xml and annotation #{annotation.id}: '#{annotation.quote}'\n"
    end
  end

  private

  def insert_ref(html, annotation)
    ref = %{<ref type='annotation' target='#{annotation.id}'>}
    begin
      html.insert(annotation.char_end, "</ref>")
      html.insert(annotation.char_start, ref)
    rescue => e
      @errors << "Unable to add ref to #{@cat_id} for annotation #{annotation.id}: #{e}"
    end
  end

  def derive_id(path)
    path.match(/[0-9]{4}/)[0]
  end

  def read_xml(path)
    if File.file?(path)
      File.open(path) { |f| Nokogiri::XML(f) }
    end
  end
end