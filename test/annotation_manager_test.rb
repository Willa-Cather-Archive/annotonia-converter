require 'fileutils'
require 'json'
require 'net/http'
require 'nokogiri'

require "minitest/autorun"
require_relative "fixtures/config.rb"
require_relative "../lib/annotation_manager"

# Stub out a few methods
class AnnotationManager
  private

  def annotation_bash_cmd(cmd, annotation)
    $published_annos << annotation
  end

  def get_flask_data(id=nil)
    file = File.read("#{File.dirname(__FILE__)}/fixtures/flask_response.json")
    return JSON.parse(file)["rows"]
  end

  def prompt_for_affirmation(message="Continue?")
  end

  def prompt_for_negation(message="Continue?")
  end

  def report_messages
  end

end

class TestAnnotationManager < Minitest::Test

  def setup
    $published_annos = []
    @manager = AnnotationManager.new
  end

  def test_initialize
    assert_equal [], @manager.flask_annotations
    assert_equal [], @manager.letters
  end

  def test_create_annotation_xml
    tei = @manager.create_annotation_xml
    # verify that it created a file
    assert File.file?($annotation_file)

    # crudely determine if the file was updated recently
    file_time = File.mtime($annotation_file)
    now = Time.new
    assert file_time > now-1
    assert file_time < now+1

    # given that two of the annotations reference another
    # there should be two less notes in the tei than in the annotations object
    assert_equal @manager.flask_annotations.length-2, tei.css("note[type='annotation']").length
    expected_text = %{<note type=\"annotation\" xml:id=\"aanno172\" target=\"anno172\" corresp=\"cat.let2161\">
  <p>It's a state.<lb/><hi rend=\"italic\">Just a fact for you, about states</hi>.</p>
</note>}
    tei_text = tei.css("note[target=anno172]").to_s
    assert_equal tei_text, expected_text

    # verify that the reference annotations return the correct id
    anno = @manager.find_annotations("@id", "000178")[0]
    anno_dup = @manager.find_annotations("@id", "000179")[0]
    assert_equal anno_dup.anno_ref_id, "000178"
    assert !anno.duplicate
    assert anno_dup.duplicate
    assert_nil anno_dup.xml
  end

  def test_delete_all_letters
    # Copy letters to be deleted for restoration after test
    backup_dir = "#{File.dirname(__FILE__)}/fixtures/letters_orig_backup"
    FileUtils.mkdir(backup_dir)
    FileUtils.cp(Dir.glob("#{$letters_in}/*"), backup_dir)

    @manager.delete_letters

    # 0000 Deleted
    assert_nil File.size?("#{$letters_in}/cat.let0000.xml")

    # 0550 Deleted
    assert_nil File.size?("#{$letters_in}/cat.let0550.xml")

    # 2161 Deleted
    assert_nil File.size?("#{$letters_in}/cat.let2161.xml")

    # 2514 Deleted
    assert_nil File.size?("#{$letters_in}/cat.let2514.xml")

    # Restore deleted letters
    FileUtils.mv(Dir.glob("#{backup_dir}/*"), $letters_in, force: true)
    FileUtils.rm_rf(backup_dir)
  end

  def test_delete_selected_letters
    # Copy example letter selection file to only delete selected letters
    FileUtils.cp("#{File.dirname(__FILE__)}/fixtures/letters_selected_example.txt", $letters_in_selected)

    # Copy letters to be deleted for restoration after test
    backup_dir = "#{File.dirname(__FILE__)}/fixtures/letters_orig_backup"
    FileUtils.mkdir(backup_dir)
    FileUtils.cp(Dir.glob("#{$letters_in}/*"), backup_dir)

    @manager.delete_letters

    # 0000 Not deleted
    assert_operator 0, :<, File.size?("#{$letters_in}/cat.let0000.xml")

    # 0550 Deleted
    assert_nil File.size?("#{$letters_in}/cat.let0550.xml")

    # 2161 Deleted
    assert_nil File.size?("#{$letters_in}/cat.let2161.xml")

    # 2514 Not deleted
    assert_operator 0, :<, File.size?("#{$letters_in}/cat.let2514.xml")

    # Restore deleted letters
    FileUtils.mv(Dir.glob("#{backup_dir}/*"), $letters_in, force: true)
    FileUtils.rm_rf(backup_dir)

    # Delete copied letter selection file
    File.delete($letters_in_selected)
  end

  def test_delete_selected_letters_skip_empty_letter_selection_file_in_letters_in_dir
    # Change $letters_in_selected to be within $letters_in
    $letters_in_selected = "#{$letters_in}/letters_selected.txt"

    # Copy example empty letter selection file
    FileUtils.copy("#{File.dirname(__FILE__)}/fixtures/letters_selected_example_empty.txt", $letters_in_selected)

    # Copy letters to be deleted for restoration after test
    backup_dir = "#{File.dirname(__FILE__)}/fixtures/letters_orig_backup"
    FileUtils.mkdir(backup_dir)
    FileUtils.cp(Dir.glob("#{$letters_in}/*"), backup_dir)

    @manager.delete_letters

    # Letter selection file not deleted
    assert File.file?($letters_in_selected)
    assert_nil File.size?($letters_in_selected)

    # Restore deleted letters
    FileUtils.mv(Dir.glob("#{backup_dir}/*"), $letters_in, force: true)
    FileUtils.rm_rf(backup_dir)

    # Delete copied letter selection file
    File.delete($letters_in_selected)
  end

  def test_run_generator
    @manager.run_generator
    assert_equal 4, @manager.letters.length
    assert_equal 22, @manager.flask_annotations.length

    # 0000
    letter0 = @manager.find_letters("@id", "let0000")[0]
    assert_equal 1, letter0.annotations.length
    assert_equal false, letter0.publishable?

    # 0550
    letter1 = @manager.find_letters("@id", "let0550")[0]
    assert_equal 1, letter1.annotations.length
    assert_equal true, letter1.publishable?

    # 2161
    letter2 = @manager.find_letters("@id", "let2161")[0]
    assert_equal 4, letter2.annotations.length
    assert_equal true, letter2.publishable?
    assert_equal ["Complete", "Needs Correction"], letter2.annotations[0].tags

    orig_xml = read_xml("#{File.dirname(__FILE__)}/fixtures/letters_orig/cat.let2161.xml")
    new_xml = read_xml("#{File.dirname(__FILE__)}/fixtures/letters_new/cat.let2161.xml")
    orig_refs = orig_xml.xpath("//tei:ref", "tei" => $tei_ns)
    new_refs = new_xml.xpath("//tei:ref", "tei" => $tei_ns)
    orig_wrongs = orig_xml.xpath("//tei:wrong", "tei" => $tei_ns)
    new_wrongs = new_xml.xpath("//tei:wrong", "tei" => $tei_ns)

    assert_equal 0, orig_refs.length
    assert_equal 4, new_refs.length

    # verify that <wrong></wrong> was added to the letter once AROUND a ref
    assert_equal 0, orig_wrongs.length
    assert_equal 1, new_wrongs.length
    assert_equal "Virginia", new_wrongs[0].text
    wrong_content = %{<wrong why=\"It's a state. Just a fact for you, about states .\">\n  <ref type="annotation" target="anno172">Virginia</ref>\n</wrong>}
    assert_equal wrong_content, new_wrongs[0].to_s

    assert_equal %{<ref type="annotation" target="anno.203">WHALE</ref>}, new_refs[0].to_s
    assert_equal letter2.warnings.length, 1

    # 2514
    # letter3 = @manager.find_letters("@id", "let2514")[0]
    # annotation 179 references 178 and so 178 should be inserted into letter 2514
    xml2514 = read_xml("#{File.dirname(__FILE__)}/fixtures/letters_new/cat.let2514.xml")
    refs = xml2514.css("ref[type=annotation]")
    assert_equal refs.length, 2
    assert_equal refs[0].attribute("target").to_s, "000178"
  end

  def test_run_generator_selected_letters
    # Copy example letter selection file to only process selected letters
    FileUtils.copy("#{File.dirname(__FILE__)}/fixtures/letters_selected_example.txt", $letters_in_selected)

    @manager.run_generator
    assert_equal 2, @manager.letters.length

    # 0000 Not selected
    letter0 = @manager.find_letters("@id", "let0000")[0]
    assert_nil letter0

    # 0550 selected
    letter1 = @manager.find_letters("@id", "let0550")[0]
    assert_equal 1, letter1.annotations.length

    # 2161 selected
    letter2 = @manager.find_letters("@id", "let2161")[0]
    assert_equal 4, letter2.annotations.length

    # 2514 not selected
    letter3 = @manager.find_letters("@id", "let2514")[0]
    assert_nil letter3

    # Delete copied letter selection file
    File.delete($letters_in_selected)
  end

  def test_run_generator_skip_empty_letter_selection_file_in_letters_in_dir
    # Change $letters_in_selected to be within $letters_in
    $letters_in_selected = "#{$letters_in}/letters_selected.txt"

    # Copy example empty letter selection file
    FileUtils.copy("#{File.dirname(__FILE__)}/fixtures/letters_selected_example_empty.txt", $letters_in_selected)

    @manager.run_generator
    assert_equal 4, @manager.letters.length

    letter_selection_present = @manager.find_letters("@file_read", $letters_in_selected)[0]
    assert_nil letter_selection_present

    # Delete copied letter selection file
    File.delete($letters_in_selected)
  end

  # annotation_bash_cmd stub above prevents updating the index
  def test_publish_letter_annotations
    @manager.publish_letter_annotations
    assert_equal 7, $published_annos.length
    # below should not have html->TEI changes because it would normally be sent back to the annotonia portion
    assert_equal "<p>It&apos;s a state.<br/><i>Just a fact for you, about states</i>.</p>", $published_annos[3]["text"]
  end

  private

  def read_xml(path)
    if File.file?(path)
      File.open(path) { |f| Nokogiri::XML(f) }
    end
  end

end
