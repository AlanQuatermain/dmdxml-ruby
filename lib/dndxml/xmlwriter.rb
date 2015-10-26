#
# Author::      Jim Dovey,  jimdovey@mac.com
# Description:: Implements the XML encoder for DnD data.
#

require 'rexml/document'

module DnDXML
	
	def write_xml_file(path, content={})
	  return if content.empty?
    root = REXML::Element.new 'document'
    root.namespace = XML_SCHEMA
    
    unless content[:spells].empty?
      elem = root.add_element 'spells'
      content[:spells].each { |spell| elem << spell.to_xml }
    end
    
    unless content[:items].empty?
      elem = root.add_element 'items'
      content[:items].each { |item| elem << item.to_xml }
    end
    
    unless content[:creatures].empty?
      elem = root.add_element 'creatures'
      content[:creatures].each { |creature| elem << creature.to_xml }
    end
    
    unless content[:lookups].empty?
      elem = root.add_element 'lookups'
      content[:lookups].each { |lookup| elem << lookup.to_xml }
    end
    
    doc = REXML::Document.new
    doc << root
    
    File.open(path, "w") do |file|
      formatter = REXML::Formatters::Pretty.new
      output = REXML::Output.new(file, 'UTF-8')
      formatter.write(doc, output)
    end
	end
	
end