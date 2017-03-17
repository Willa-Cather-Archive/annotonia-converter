#!/usr/bin/env ruby

require 'fileutils'

require_relative 'config'
require_relative 'lib/annotation_manager'

manager = AnnotationManager.new
manager.delete_letters

