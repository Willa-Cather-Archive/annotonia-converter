# Annotation Generator
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
#   $ ruby generate.rb
#   compare output_dir files with original TEI to view annotation markup
#   new annotations output into the annotation file


require 'fileutils'
require 'json'
require 'net/http'

require_relative 'config'
require_relative 'lib/annotation_manager'

manager = AnnotationManager.new
manager.run_generator
