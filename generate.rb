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

@flask_url = URI("http://rosie.unl.edu:5000/search")
@letters_dir = "letters_orig"
@output_dir = "letters_new"
@annotations = "annotations.txt"
@tei_ns = "http://www.tei-c.org/ns/1.0"

def annotate(letterID, element, range, quote, annotationID)
  start = range[0]["startOffset"].to_i
  ending = range[0]["endOffset"].to_i
  characters = (start..ending)
  # This portion is going to need to take an element 
  # and alter the content to have the following
  # <ref type="annotation" target="ann:00162"/>

  highlight = element.inner_html[characters]
  puts "\n\n\n"
  puts "element #{element.content}"
  puts "highlight #{highlight}."
  puts "quote #{quote}."
  # TODO should check to see if previously annotated?  Otherwise will be <ref><ref></ref></ref>
  if highlight.strip == quote.strip
    new_content = element.inner_html
    # put the closing tag on before the starting tag or the index == kablam
    new_content.insert(ending, "</ref>")
    new_content.insert(start, "<ref type='annotation' target='#{annotationID}'>")
    element.inner_html = new_content
  else
    puts "The annotation for cat.let#{letterID}.xml no longer matches"
    puts "Requested: #{quote}."
    puts "Current match: #{highlight}."
  end
end

# CAUTION:  Don't remove code checking if output_dir exists
#  because if it is left empty this would remove /* instead of a relative path
def delete_generated
  if @output_dir && @output_dir.length > 0
    puts "Running this script will remove files in the #{@output_dir} directory"
    puts "and it will wipe the annotations file #{@annotations}"
    puts "Continue?  y/N"
    input = gets.chomp
    if (input == "y" || input == "Y")
      puts "Removing files in #{@output_dir}"
      files = Dir.glob("#{@output_dir}/*")
      FileUtils.rm(files)
      puts "Removing #{@annotations}"
      FileUtils.rm(@annotations) if File.file?(@annotations)
    else
      exit
    end
  else
    puts "Script requires an output directory before it can run"
    puts "Please fill in the variable at the top of this script"
    exit
  end
end

# post request to URL and return array of result hashes
def get_flask_annotations
  res = Net::HTTP.get(@flask_url)
  json = JSON.parse(res)
  if json["rows"]
    return json["rows"]
  else
    raise "Unexpected response from flask at #{@flask_url}\n\n#{json}"
  end
end

def open_xml(id)
  filename = "#{@letters_dir}/cat.let#{id}.xml"
  file = nil
  if File.file?(filename)
    file = File.open(filename) { |f| Nokogiri::XML(f) }
    return file
  end
end

# TODO this is only using first xpath....be prepared to expand?
def prep_xpath(xpath_range, index=0, pos="start")
  xpath = xpath_range[index][pos]
  # chop the beginning off until "tei[1]"
  xpath.sub!(/.*\/tei\[1\]/, "")
  # add ns also double slashes to overcome boilerplate extra elements
  # TODO this will be a problem if boilerplate REMOVES elements
  xpath.gsub!(/\//, "//tei:")
  return "//tei:TEI#{xpath}"
end

def main
  delete_generated
  res = get_flask_annotations
  res.each do |anno|
    id = anno["letterID"]
    file = open_xml(id)
    if file
      xpath = prep_xpath(anno["ranges"])
      puts xpath
      element = file.at_xpath(xpath, "tei" => @tei_ns)
      annotate(id, element, anno["ranges"], anno["quote"], anno["id"])
      File.write("#{@output_dir}/cat.let#{id}.xml", file.to_xml)

      # anno_xml = create_annotation_xml(anno)
      File.open(@annotations, 'a') do |f|
        f.puts "hello"
      end
    else
      # puts "No xml file found for id cat.let#{id}.xml"
    end
  end
end

main