require File.join(File.dirname(__FILE__), *%w[.. lib dndxml])

require 'rubygems'
require 'test/unit'
require 'mocha'

include DnDXML

def fixture(name)
	File.read fixture_path(name)
end

def fixture_path(name)
	File.join File.dirname(__FILE__), 'fixtures', name
end

def absolute_project_path
	File.expand_path(File.join(File.dirname(__FILE__), '..'))
end
