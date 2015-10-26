#
# Author::      Jim Dovey,  jimdovey@mac.com
# Description:: Reads a DnD XML document, yielding arrays of Spells, Items, Creatures and/or LookupTables.
#

require "rexml/document"

module DnDXML
  
  def read_xml_file(path)
    doc = REXML::Document.new(File.read(path)) || return {}
    return {} unless doc.root.name == 'document'
    return {} unless doc.root.namespace == XML_SCHEMA
    
    result = {}
    
    spells = []
    doc.root.elements.each('./spells/spell') do |element|
      spells << Spell.new(element)
    end
    result[:spells] = spells unless spells.empty?
    
    items = []
    doc.root.elements.each('./items/item') do |element|
      items << MagicItem.new(element)
    end
    result[:items] = items unless items.empty?
    
    creatures = []
    doc.root.elements.each('./creatures/creature') do |element|
      creatures << Creature.new(element)
    end
    result[:creatures] = creatures unless creatures.empty?
    
    lookups = []
    doc.root.elements.each('./lookups/lookup') do |element|
      lookups << LookupTable.new(element)
    end
    result[:lookups] = lookups unless lookups.empty?
    
    result
  end
  
end
