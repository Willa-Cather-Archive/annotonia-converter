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

  def get_flask_data(id=nil)
    file = File.read("#{File.dirname(__FILE__)}/fixtures/flask_response.json")
    return JSON.parse(file)["rows"]
  end

  def prompt_input
    return "y"
  end
end

class TestAnnotationManager < Minitest::Test

  def setup
    @manager = AnnotationManager.new
  end

  def test_initialize
    assert_equal [], @manager.flask_annotations
    assert_equal [], @manager.letters
  end

  def test_run_generator
    @manager.run_generator
    assert_equal 2, @manager.letters.length
    assert_equal 14, @manager.flask_annotations.length

    orig_xml = read_xml("#{File.dirname(__FILE__)}/fixtures/letters_orig/cat.let2161.xml")
    new_xml = read_xml("#{File.dirname(__FILE__)}/fixtures/letters_new/cat.let2161.xml")
    orig_refs = orig_xml.xpath("//tei:ref", "tei" => $tei_ns)
    new_refs = new_xml.xpath("//tei:ref", "tei" => $tei_ns)

    assert_equal 0, orig_refs.length
    assert_equal 4, new_refs.length

    assert_equal %{<ref type="annotation" target="AVOF5og8QF3Cd7E0UXNc">WHALE</ref>}, new_refs[0].to_s
  end

  def test_publish_all

  end

  private

  def read_xml(path)
    if File.file?(path)
      File.open(path) { |f| Nokogiri::XML(f) }
    end
  end

end