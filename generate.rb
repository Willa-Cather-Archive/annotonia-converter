# Annotation Generator
#
# Spring 2016 for Cather Archive
#
# Requires annotator.py to be running
# 
# Setup:
#   gem install nokogiri
# Run:
#   put TEI letters files in "letter_dir" path
#   $ ruby generate.rb
#   compare output_dir files with original TEI to view annotation markup
#   new annotations output into the annotation file


require 'fileutils'
require 'json'
require 'net/http'
require 'nokogiri'

# change the below if you wish to write to different files / directories
@annotations = "annotations.txt"
@flask_url = URI("http://rosie.unl.edu:5000/search")
@letters_dir = "letters_orig"
@output_dir = "letters_new"
@tei_ns = "http://www.tei-c.org/ns/1.0"
@warnings = "warnings.txt"

@tei_cases = ["teiHeader", "fileDesc", "titleStmt", "respStmt", "publicationStmt",
              "addrLine", "seriesStmt", "sourceDesc", "persName", "msDesc",
              "handDesc", "encodingDesc", "editorialDecl", "listPrefixDef",
              "placeName"]
              # "msIdentifier", "msContents", "physDesc", "objectDesc", "revisionDesc"


def add_ref(element_html, start, ending, annotationID)
  new_content = element_html
  # put the closing tag on before the starting tag or the index == kablam
  begin
    new_content.insert(ending, "</ref>")
    new_content.insert(start, "<ref type='annotation' target='#{annotationID}'>")
    return new_content
  rescue
    return nil
  end
end

def add_annotate(letterID, element, range, quote, annotationID)
  start = range[0]["startOffset"].to_i
  ending = range[0]["endOffset"].to_i
  characters = (start..ending)
  # This portion is going to need to take an element 
  # and alter the content to have the following
  # <ref type="annotation" target="ann:00162"/>

  highlight = element.inner_html[characters]
  
  # TODO should check to see if previously annotated?  Otherwise will be <ref><ref></ref></ref>
  if highlight.strip == quote.strip
    new_content = add_ref(element.inner_html, start, ending, annotationID)
    if new_content
      element.inner_html = new_content
    else
      puts "Unable to add #{annotationID} ref to cat.let#{letterID}.xml: '#{quote}'"
      write_to_file(@warnings, "Unable to add #{annotationID} ref to cat.let#{letterID}.xml: #{quote}")
    end
  else
    puts "Attempting guess for cat.let#{letterID}.xml for annotation '#{quote}'"
    write_to_file(@warnings, "Check file cat.let#{letterID}.xml for annotation '#{quote}' placement")
    first_match = element.inner_html.index(quote)
    first_match_end = quote.length + first_match
    new_content = add_ref(element.inner_html, first_match, first_match_end, annotationID)
    element.inner_html = new_content
  end
end

# move later
def annotate_tei(id, tei, annotation)
  xpath = prep_xpath(annotation["ranges"])
  # puts xpath
  element = tei.at_xpath(xpath, "tei" => @tei_ns)
  if element
    add_annotate(id, element, annotation["ranges"], annotation["quote"], annotation["id"])
  else
    puts "No element found at xpath #{xpath} for cat.let#{id}.xml"
  end
end

def create_annotation_xml(annotation)
  text = annotation["text"]
  anno_id = annotation["id"]
  if text
    note = %{
      <note type='annotation' xml:id='#{anno_id}' target='#{anno_id}'>
      #{text}
      </note>
    }
    write_to_file(@annotations, note)
  end
end

# CAUTION:  Don't remove code checking if output_dir exists
#  because if it is left empty this would remove /* instead of a relative path
def delete_generated
  if @output_dir && @output_dir.length > 0
    puts "Running this script will remove files in the #{@output_dir} directory"
    puts "and it will wipe the files #{@annotations} and #{@warnings}"
    puts "Continue?  y/N"
    input = gets.chomp
    if (input == "y" || input == "Y")
      puts "Removing files in #{@output_dir}"
      files = Dir.glob("#{@output_dir}/*")
      FileUtils.rm(files)
      puts "Removing #{@annotations} and #{@warnings}"
      FileUtils.rm(@annotations) if File.file?(@annotations)
      FileUtils.rm(@warnings) if File.file?(@warnings)
    else
      exit
    end
  else
    puts "Script requires an output directory before it can run"
    puts "Please fill in the variable at the top of this script"
    exit
  end
end

def derive_letter_id(pathname)
  begin
    return pathname.match(/[0-9]{4}/)[0]
  rescue
    puts "unable to process: #{pathname} has invalid filename for cather letter"
  end
end

# post request to URL and return array of result hashes
def get_flask_annotations(id=nil)
  url = id ? "#{@flask_url}?letterID=#{id}" : @flask_url
  res = Net::HTTP.get(URI.parse(url))
  json = JSON.parse(res)
  if json["rows"]
    return json["rows"]
  else
    raise "Unexpected response from flask at #{url}"
  end
end

def read_xml(id)
  if File.file?(id)
    file = File.open(id) { |f| Nokogiri::XML(f) }
    return file
  end
end

# the annotator is saving things as "persname" when they should be "persName"
# so need to check against a list and alter xpath
def tei_casing(xpath)
  @tei_cases.each do |element|
    xpath.gsub!(element.downcase, element)
  end
  return xpath
end

# TODO this is only using first xpath....be prepared to expand?
def prep_xpath(xpath_range, index=0, pos="start")
  xpath = xpath_range[index][pos]
  # chop the beginning off until "tei[1]"
  xpath.sub!(/.*\/tei\[1\]/, "")
  xpath = tei_casing(xpath)
  # add ns also double slashes to overcome boilerplate extra elements
  # TODO this will be a problem if boilerplate REMOVES elements
  xpath.gsub!(/\//, "//tei:")
  return "//tei:TEI#{xpath}"
end

def write_to_file(filename, text)
  File.open(filename, 'a') do |f|
    f.puts text
  end
end


def main
  letters = Dir.glob("#{@letters_dir}/*")
  if letters
    delete_generated
    letters.each do |letter_path|
      id = derive_letter_id(letter_path)
      if id
        tei = read_xml(letter_path)
        annotations = get_flask_annotations(id)
        annotations.each do |annotation|
          annotate_tei(id, tei, annotation)
          create_annotation_xml(annotation)
        end
        File.write("#{@output_dir}/cat.let#{id}.xml", tei.to_xml)
      end
    end
  else
    puts "Please add letters to the #{@letters_dir} directory and try rerunning the script"
  end
end

main