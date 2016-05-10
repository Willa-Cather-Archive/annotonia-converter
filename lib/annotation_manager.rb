require_relative 'flask_annotation'
require_relative 'letter'

class AnnotationManager
  attr_reader :flask_annotations
  attr_reader :letters

  def initialize
    @flask_annotations = []
    @letters = []
  end

  def find_annotations(attr_type, value)
    @flask_annotations.find_all { |anno| anno.instance_variable_get(attr_type) == value }
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
    print_annotations_for_letters
    report_messages
  end

  private

  def combine_messages(type)
    messages = @letters.map { |l| l.instance_variable_get(type) }
    messages.flatten.compact
  end

  def create_annotations
    annotations = get_flask_data
    annotations.each do |anno|
      @flask_annotations << FlaskAnnotation.new(anno)
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
      puts "Removing #{$annotation_file} and #{$warnings_file}"
      FileUtils.rm($annotation_file) if File.file?($annotation_file)
      FileUtils.rm($warnings_file) if File.file?($warnings_file)
    else
      exit
    end
  end

  private

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

  def print_annotations_for_letters
    letter_ids = @letters.map { |l| l.id }
    annotations = @flask_annotations.map do |a| 
      if letter_ids.include?(a.letter_id)
        a.xml
      end
    end
    File.write("#{$annotation_file}", annotations.compact.join("\n"))
  end

  def prompt_input
    puts "Running this script will remove files in the #{@output_dir} directory"
    puts "and it will wipe the files #{$annotation_file} and #{$warnings_file}"
    puts "Continue?  y/N"
    input = gets.chomp
  end
end