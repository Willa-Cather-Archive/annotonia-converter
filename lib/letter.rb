require 'fileutils'
require 'htmlentities'
require 'nokogiri'

class Letter
  attr_reader :annotations
  attr_reader :id
  attr_reader :cat_id
  attr_reader :file_read
  attr_reader :file_write

  attr_accessor :errors
  attr_accessor :warnings
  attr_accessor :xml

  def initialize(path, annotations)
    @file_read = path
    @id = derive_id(path)
    @cat_id = "cat.#{@id}"
    @file_write = "#{$letters_out}/#{@cat_id}.xml"
    @annotations = annotations

    @errors = []
    @warnings = []
    @xml = read_xml(path)
  end

  def add_ref(annotation)
    element = @xml.at_xpath(annotation.xpath, "tei" => $tei_ns)

    if !element || element.inner_html.empty?
      # If no element found or the element is self-closing (e.g. <anchor/>),
      # try looking at the parent xpath

      # If self-closing element, shift highlight range forward by length of HTML
      if element
        annotation.char_start += element.to_html.length
        annotation.char_end += element.to_html.length
      end

      element = xpath_parent(annotation.xpath)
    end

    if element
      range = (annotation.char_start..annotation.char_end)
      highlight = element.inner_html[range]

      # If highlight not found, check in sibling elements, then in parent
      if highlight.nil?
        sibling_index = annotation.xpath[/\[(\d+)\]$/]

        # If xpath not first sibling, start over at 1
        sibling_index = 1 if sibling_index != 1

        # Loop through sibling elements
        while highlight.nil?
          element = xpath_sibling(annotation.xpath, sibling_index)

          # No more siblings exist
          break if element.nil?

          # Extract highlight from sibling
          highlight = element.inner_html[range]

          sibling_index += 1
        end

        # If highlight still not found, look in parent element
        element = xpath_parent(annotation.xpath)
        highlight = element.inner_html[range]

        # If still no highlight found, set highlight to empty string
        # to prevent error on Nil.strip below
        highlight = "" if highlight.nil?
      end

      # if the start - end range does not match the annotation quote, then something
      # differs between the HTML and the TEI characters in the xpath
      # so pick the first instance of the annotation quote and use that instead
      new_content = nil
      if highlight.strip != annotation.quote.strip
        # quotation is not exactly where expected, try to find single instance
        multiple_quotes = element.inner_html.scan(annotation.quote).length > 1
        if multiple_quotes
          @warnings << %{Guessed ref location in #{@cat_id}.xml for #{annotation.id} ('#{annotation.quote}') placement. xpath: annotation.xpath\n }
        end
        begin
          annotation.char_start = element.inner_html.index(annotation.quote)
          annotation.char_end = annotation.quote.length + annotation.char_start
          new_content = update_html(element.inner_html, annotation)
        rescue => e
          @errors << "Unable to add ref to #{@cat_id}.xml for #{annotation.id}: #{e}\n  (This may mean the highlighted string in HTML contains characters that the TEI does not)"
        end
      else
        # found annotation exactly where expected, carry on!
        new_content = update_html(element.inner_html, annotation)
      end

      if new_content && new_content.class == String
        element.inner_html = new_content
      end
    else
      @errors << "No element found at xpath #{annotation.xpath} for #{cat_id}.xml and annotation #{annotation.id}: '#{annotation.quote}'\n"
    end
  end

  def publishable?
    # anything that is not completed will be listed here
    uncompleted = @annotations.reject { |anno| anno.publishable }
    return uncompleted.length == 0
  end

  private

  def derive_id(path)
    path.match(/let[0-9]{4}/)[0]
  end

  def insert_annotation(html, location, anno_id)
    elements = { :opening => "<ref type='annotation' target='#{anno_id}'>", :closing => "</ref>" }
    return insert_ref(html, location, elements, anno_id)
  end

  def insert_annotation_and_badtei(html, location, anno_id, badtext)
    elements = { :opening => "<wrong why='#{badtext}'><ref type='annotation' target='#{anno_id}'>",
                 :closing => "</ref></wrong>"
               }
    return insert_ref(html, location, elements, anno_id)
  end

  def insert_badtei(html, location, anno_id, badtext)
    elements = { :opening => "<wrong why='#{badtext}'>", :closing => "</wrong>" }
    return insert_ref(html, location, elements, anno_id)
  end

  def insert_ref(html, location, elements, anno_id)
    begin
      html.insert(location[:end], elements[:closing])
      html.insert(location[:start], elements[:opening])
    rescue => e
      @errors << "Unable to add ref to #{@cat_id} for annotation #{anno_id}: #{e}"
    end
    return html
  end

  def read_xml(path)
    if File.file?(path)
      File.open(path) { |f| Nokogiri::XML(f) }
    end
  end

  def update_html(html, annotation)
    tags = annotation.tags
    location = { :start => annotation.char_start, :end => annotation.char_end }
    updated = html
    # this text will only be embedded for the <wrong> tags
    text_encoded = HTMLEntities.new.encode(strip_html(annotation.text))
    if tags.include?("Published")
      # at this time, do not do anything, may change in the future
    elsif tags.include?("Complete") && tags.include?("Needs Correction")
      updated = insert_annotation_and_badtei(html, location, annotation.anno_ref_id, text_encoded)
    elsif tags.include?("Needs Correction")
      updated = insert_badtei(html, location, annotation.anno_ref_id, text_encoded)
    elsif tags.include?("Complete")
      updated = insert_annotation(html, location, annotation.anno_ref_id)
    end
    return updated
  end

  def strip_html(html)
    tag_list = %w(
      a
      blockquote
      br
      div
      em
      i
      img
      li
      ol
      p
      span
      ul
      video
    )

    tag_list.each { |tag|
      html.gsub!(/<#{tag}.*?>/i, " ")
      html.gsub!(/<\/#{tag}>/i, " ")
    }

    html.gsub!(/[[:space:]]+/, " ")
    html.strip!

    return html
  end

  def xpath_parent xpath
    return @xml.at_xpath(xpath.partition(/\/\/tei\:\w+\[\d+\]$/)[0], "tei" => $tei_ns)

  end

  def xpath_sibling xpath, index
    return @xml.at_xpath(xpath.gsub(/\[\d+\]$/, "[#{index}]"), "tei" => $tei_ns)
  end
end
