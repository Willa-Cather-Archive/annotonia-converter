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

  def prompt_input
    return "y"
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

  def test_run_generator
    @manager.run_generator
    assert_equal 3, @manager.letters.length
    assert_equal 22, @manager.flask_annotations.length

    # 0000
    letter0 = @manager.letters[0]
    assert_equal 1, letter0.annotations.length
    assert_equal false, letter0.publishable?

    # 0550
    letter1 = @manager.letters[1]
    assert_equal 1, letter1.annotations.length
    assert_equal true, letter1.publishable?

    # 2161
    letter2 = @manager.letters[2]
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
    wrong_content = %{<wrong>\n  <ref type="annotation" target="anno.172">Virginia</ref>\n</wrong>}
    assert_equal wrong_content, new_wrongs[0].to_s

    assert_equal %{<ref type="annotation" target="anno.203">WHALE</ref>}, new_refs[0].to_s
    assert_equal letter2.warnings.length, 1
  end

  # does not actually update the index, see annotation_bash_cmd at top of this file
  def test_publish_letter_annotations
    @manager.publish_letter_annotations
    assert_equal 5, $published_annos.length
    assert_equal "<p>It&apos;s a state.</p>", $published_annos[1]["text"]
  end

  private

  def read_xml(path)
    if File.file?(path)
      File.open(path) { |f| Nokogiri::XML(f) }
    end
  end

end
