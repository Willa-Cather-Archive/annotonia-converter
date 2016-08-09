# Publisher
#
# Spring 2016 for Cather Archive
#
# Requires annotator.py to be running on accessible port
#
# Setup:
#   $ gem install nokogiri
#   edit config.rb file if required
#
# Test (skip this part if you are not a developer):
#   $ gem install bundler
#   $ bundle install
#   $ rake test
#
# Run:
#   put TEI letters files in "letter_dir" path
#   $ ruby publish.rb
#   for all of the letters in the letters_orig directory, this
#   script will change the tag status to "Published"


require_relative 'config'
require_relative '../lib/annotation_manager'

manager = AnnotationManager.new
manager.publish_all_annotations
