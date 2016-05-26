require 'fileutils'
require 'json'
require 'net/http'
require 'open3'

require_relative 'flask_annotation'
require_relative 'letter'

class AnnotationManager
  attr_reader :flask_annotations
  attr_reader :letters

  def initialize
    @flask_annotations = []
    @letters = []
  end

  def generate_all_annotation_json
    create_annotations
    update_annotation_file
  end

  def find_annotations(attr_type, value)
    @flask_annotations.find_all { |anno| anno.instance_variable_get(attr_type) == value }
  end

  def publish_all_annotations
    create_letters
    create_annotations
    to_publish = bulk_change_tags(@letters, "Published")
    update_cloud_annotations(to_publish)
  end

  def report_messages
    warnings = combine_messages("@warnings").compact
    errors = combine_messages("@errors").compact
    combined = warnings + errors
    if combined.length > 0
      File.open("#{$warnings_file}", "a") { |f| f.puts(combined.join("\n")) }
      puts %{\nFound #{warnings.length} warning(s) and #{errors.length} error(s). Please review #{$warnings_file}}
    end
  end

  def run_generator
    delete_generated
    create_letters
    create_annotations
    insert_references
    update_annotation_file_by_letters
    report_messages
  end

  private

  def bulk_change_tags(letter_objs, tag_name)
    updated = []
    letter_objs.each do |letter|
      annos = find_annotations("@letter_id", letter.id)
      annos.each do |anno|
        # clone the object
        new_res = JSON.parse(JSON.generate(anno.raw_res))
        # Make sure that you override the entire array in tags
        new_res["tags"] = ["Published"]
        updated << new_res
      end
    end
    return updated
  end

  def combine_messages(type)
    messages = @letters.map { |l| l.instance_variable_get(type) }
    messages.flatten.compact
  end

  def create_annotations
    annotations = get_flask_data
    annotations.each do |anno|
      flask_annotation = FlaskAnnotation.new(anno)
      # verify that only annotations that are complete are added
      if flask_annotation.process_bool
        @flask_annotations << flask_annotation
      end
    end
  end

  def create_letters
    letter_paths = Dir.glob("#{$letters_in}/*")
    letter_paths.each do |path|
      @letters << Letter.new(path)
    end
  end

  # CAUTION:  Don't remove code checking if output_dir exists
  #  because if it is left empty this would remove /* instead of a relative path
  def delete_generated
    input = prompt_input
    if (input == "y" || input == "Y")
      if $letters_out && $letters_out.length > 0
        puts "Removing files in #{$letters_out}"
        files = Dir.glob("#{$letters_out}/*")
        FileUtils.rm(files)
      end
      puts "Removing #{$warnings_file}"
      FileUtils.rm($warnings_file) if File.file?($warnings_file)
    else
      exit
    end
  end

  def create_annotation_json(annotation)
    return { "letter_id" => annotation.letter_id, "xml" => annotation.xml }
  end

  def get_flask_data(id=nil)
    url = id ? "#{$flask_url}?letterID=#{id}" : $flask_url
    res = Net::HTTP.get(URI.parse(URI.encode(url)))
    json = JSON.parse(res)
    if json["rows"]
      return json["rows"]
    else
      raise "Unexpected response from flask at #{url}"
    end
  end

  def insert_references
    @letters.each do |letter|
      annotations = find_annotations("@letter_id", letter.id)
      if annotations
        annotations.each { |a| letter.add_ref(a) }
        File.write("#{$letters_out}/#{letter.cat_id}.xml", letter.xml)
      end
    end
  end

  def update_cloud_annotations(annotation_json)
    # TODO I HATE THIS but I suck at net/http + PUT, apparently?
    annotation_json.each do |anno|
      uri = "#{$anno_store_url}#{anno['id']}"
      cmd = "curl -i -H 'Content-Type: application/json' -X PUT -d '#{JSON.generate(anno)}' #{uri} | grep 'HTTP/1.1'"
      Open3.popen3(cmd) do |stdin, stdout, stderr|
        puts stdout.read
        puts stderr.read
      end
    end
  end

  def update_annotation_file_by_letters
    letter_ids = @letters.map { |l| l.id }
    update_annotation_file(letter_ids)
  end

  # read in the existing file, update / add json, then write to file
  # TODO make this nicer
  def update_annotation_file(letter_ids=nil)
    file = File.read("#{$annotation_file}")
    anno_json = file ? JSON.parse(file) : {}

    @flask_annotations.each do |a| 
      if letter_ids.nil?
        anno_json[a.id] = create_annotation_json(a)
      elsif letter_ids.include?(a.letter_id)
        anno_json[a.id] = create_annotation_json(a)
      end
    end

    File.write("#{$annotation_file}", JSON.pretty_generate(anno_json))
  end

  def prompt_input
    puts "Running this script will remove files in the #{@output_dir} directory"
    puts "and it will wipe the files #{$annotation_file} and #{$warnings_file}"
    puts "Continue?  y/N"
    return gets.chomp
  end
end