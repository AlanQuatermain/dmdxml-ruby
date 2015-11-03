# 
# = fcs.rb
#
# Author:: 				Jim Dovey, jimdovey@mac.com
# Description:: 	Implements the DnD XML handler base.
#

$:.unshift File.dirname(__FILE__) # For use/testing when no gem is installed

# core
require 'fileutils'

require 'rubygems'

require 'ext/string'
require 'ext/Symbol'
require 'ext/Number'
require 'ext/NilClass'

# The DnDXML module implements a set of classes for dealing with DnD spell, item, and
# creature data and their representation in an XML format.
module DnDXML
	
	#
	# The path to the RNC XML schema.
	#
	SCHEMA_PATH = File.join(File.dirname(__FILE__), 'dnd.rnc')
	
	class << self
		attr_accessor :debug, :test_mode
		
		#
		# Sets test mode based on an environment variable.
		#
		def set_test_mode
			str = ENV["DNDXML_TEST_MODE"]
			self.test_mode = str.nil? ? false : str.to_bool
		end
	end
	
	#
	# Enable/disable debug logging.
	#
	# Default::  false
	#
	self.debug = false
	
	#
	# Set to true when running tests to provide a little more debugging assistance.
	#
	# Default::  false
	#
	self.test_mode = ENV["DNDXML_TEST_MODE"].nil? ? false : ENV["DNDXML_TEST_MODE"].to_bool
	
	VERSION = '0.1'
  
  XML_SCHEMA = 'http://alanquatermain.me/dnd/schema'
	
	class InvalidXMLError < RuntimeError
		# attr_reader :error_info
		#
		# def initialize(info)
		# 	@error_info = info
		# end
	end
	
end

require 'dndxml/xmlwriter'
require 'dndxml/xmlreader'
require 'dndxml/description'
require 'dndxml/spell'
require 'dndxml/item'
require 'dndxml/creature'
require 'dndxml/lookup'
