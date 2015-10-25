#
# Author::      Jim Dovey,  jimdovey@mac.com
# Description:: Implements the DnDXML::MagicItem class.
#

require 'rexml/document'

module DnDXML
	
	class MagicItem
		
		ARMOR = :armor
		POTION = :potion
		RING = :ring
		ROD = :rod
		SCROLL = :scroll
		STAFF = :staff
		WAND = :wand
		WEAPON = :weapon
		WONDROUS_ITEM = :wondrous_item
		
		ALL_TYPES = [ARMOR, POTION, RING, ROD, SCROLL, STAFF, WAND, WEAPON, WONDROUS_ITEM]

		COMMON = :common
		UNCOMMON = :uncommon
		RARE = :rare
		VERY_RARE = :very_rare
		LEGENDARY = :legendary
		ARTIFACT = :artifact
		VARIES = :varies
		
		RARITIES = [COMMON, UNCOMMON, RARE, VERY_RARE, LEGENDARY, ARTIFACT, VARIES]
		
		# Boolean values
		attr_accessor :requires_attunement
		
		# String values
		attr_accessor :title, :subtype, :restrictions
		
		# Symbol values
		attr_accessor :type, :rarity
		
		# Description
		attr_accessor :description
		
		attr_reader :attunement_info
		attr_reader :subtitle
		
		def initialize
			@requires_attunement = true
			@type = WONDROUS_ITEM
			@rarity = RARE
		end
		
		def initialize(xmlnode)
			raise ArgumentError.new("Input is not an <item> element") unless xmlnode.node_type == :element and xmlnode.name == 'item'
			
			read_attributes xmlnode.attributes
			
			xmlnode.elements.each do |element|
				case element.name
				when 'title'
					@title = element.text
				when 'type'
					@type = element.text.to_sym
					raise InvalidXMLError.new "Unknown item type '#{element.text}'" unless ALL_TYPES.contains? @type
					@subtype = element.attributes['otherInfo']
				when 'description'
					@description = Description.new(element)
				end
			end
		end
		
		def subtitle
			str = @type.to_s.capitalize
			str << " (#{@subtype})" unless @subtype.nil? or @subtype.empty?
			str << ", #{@rarity.to_s.capitalize}"
			if @requires_attunement
				str << " (requires attunement"
				str << " by a #{@restrictions}" unless @restrictions.nil? or @restrictions.empty?
				str << ")"
			end
			str
		end
		
		def to_xml
			root = REXML::Element.new 'item'
			root.add_attribute 'rarity', @rarity.to_s
			root.add_attribute 'requiresAttunement', 'true' if @requiresAttunement
			root.add_attribute 'restrictions', @restrictions unless @restrictions.nil? or @restrictions.empty?
			
			root.add_element('title').add_text(@title)
			
			type_element = root.add_element('type').add_text(@type)
			type_element.add_attribute 'otherInfo', @subtype unless @subtype.nil? or @subtype.empty?
			
			root << @description.to_xml
			root
		end
		
		def to_s
			str = "#{@title}\n"
			str << "#{subtitle}\n"
			str << @description.to_s
			str << "\n"
		end
		
		private
		
		def read_attributes(attrs)
			raise InvalidXMLError.new "<item> element MUST have a 'rarity' attribute" if attrs['rarity'].nil?
			
			attn = attrs['requiresAttunement']
			
			@requires_attunement = attn.nil? ? false : attn.to_bool
			@restrictions = attrs['restrictions']
			@rarity = attrs['rarity'].to_sym
			raise InvalidXMLError.new "<item> element 'rarity' attribute has unrecognised value '#{@rarity.to_s}'" unless RARITIES.contains? @rarity
		end
		
	end
	
end
