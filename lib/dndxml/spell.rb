#
# Author::      Jim Dovey,  jimdovey@mac.com
# Description:: Implements the DnDXML::Spell class.
#

require 'rexml/document'

module DnDXML
	
	# Spell schools
	module SpellSchool
		ABJURATION = :abjuration
		CONJURATION = :conjuration
		DIVINATION = :divination
		ENCHANTMENT = :enchantment
		EVOCATION = :evocation
		ILLUSION = :illusion
		NECROMANCY = :necromancy
		TRANSMUTATION = :transmutation
		
		ALL = [ABJURATION, CONJURATION, DIVINATION, ENCHANTMENT, EVOCATION, ILLUSION, NECROMANCY, TRANSMUTATION]
	end
	
	# Spellcasting classes
	module SpellClass
		BARD = :bard
		CLERIC = :cleric
		DRUID = :druid
		PALADIN = :paladin
		RANGER = :ranger
		SORCERER = :sorcerer
		WARLOCK = :warlock
		WIZARD = :wizard
		
		ALL = [BARD, CLERIC, DRUID, PALADIN, RANGER, SORCERER, WARLOCK, WIZARD]
	end
	
	class Spell
		
		# A special sub-type for things which have a value and a unit type.
		class UnitType
			attr_accessor :value, :unit
			
			def initialize(*args)
				case args[0]
				when REXML::Element
					text = args[0].text
					@value = text.number? ? text.to_i : text
					@unit = args[0].attributes['unit']
				when Numeric
					raise ArgumentError if args[1].nil?
					@value = args[0]
					@unit = args[1].to_s
				when String
					@value = args[0]
					@unit = args[1] unless args[1].nil?
				else
					raise ArgumentError
				end
			end
			
			def to_s
				return @value if @value.kind_of? String
				return "#{@value} #{@unit}" if @value == 1
				return "#{@value} #{pluralized_unit}"
			end
			
			private
			
			def pluralized_unit
				return '' if @unit.empty?
				return 'feet' if @unit == 'foot'
				return "#{@unit}s"
			end
		end
		
		# Boolean values
		attr_accessor :verbal, :somatic, :concentration, :ritual
		
		# String values
		attr_accessor :title, :school, :materials
		
		# Integer values
		attr_accessor :level
		
		# UnitType values
		attr_accessor :casting_time, :range, :duration
		
		# Array values
		attr_accessor :classes
		
		# Description
		attr_accessor :description
		
		def initialize(*args)
			if args[0].is_a? REXML::Element then
				load_xml(args[0])
			else
				@verbal = false
				@somatic = false
				@concentration = false
				@ritual = false
				@school = SpellSchool::ABJURATION
				@level = 0
				@casting_time = UnitType.new(1, 'action')
				@range = UnitType.new('touch', nil)
				@duration = UnitType.new('instantaneous', nil)
				@classes = []
				@materials = nil
			end
		end
		
		def to_xml
			element = REXML::Element.new 'spell'
			
			element.add_attribute('ritual', 'true') if @ritual
			element.add_attribute('verbal', 'true') if @verbal
			element.add_attribute('somatic', 'true') if @somatic
			
			element.add_element('title').add_text(@title)
			element.add_element('level').add_text(@level.to_s)
			element.add_element('school').add_text(@school.to_s)
			
			@classes.each do |klass|
				element.add_element('class').add_text(klass.to_s)
			end
			
			element.add_element('castingtime', {:unit => @casting_time.unit}).add_text(@casting_time.value.to_s)
			element.add_element('range', {:unit => @range.unit}).add_text(@range.value.to_s)
			delem = element.add_element('duration').add_text(@duration.value.to_s)
			delem.add_attribute('concentration', 'true') if @concentration
			
			element.add_element('materials').add_text(@materials) unless @materials.nil? or @materials.empty?
			
			element.add_element(@description.to_xml)
			
			element
		end
		
		def to_s
			str = "#{@title}\n"
			str << "#{subtitle}\n"
			str << "#{@classes.map { |sym| sym.to_s.capitalize }.join(' / ')}\n"
			str << "Casting time: #{@casting_time.to_s}\n"
			str << "Range: #{@range.to_s}\n"
			str << "Components: #{component_str}\n"
			str << "Duration: #{@duration.to_s}#{@concentration ? ' (requires concentration)' : ''}\n"
			str << "#{@description.to_s}\n"
		end
		
		private
		
		def load_xml(xmlnode)
			raise ArgumentError.new("Input is not a <spell> element") unless xmlnode.node_type == :element and xmlnode.name == 'spell'
			
			# some boolean values from attributes
			read_boolean_attrs(xmlnode.attributes)
			
			# everything else lives on a sub-element
			xmlnode.elements.each do |element|
				case element.name
				when 'title'
					@title = element.text
				when 'level'
					@level = element.text.to_i
				when 'school'
					@school = element.text.to_sym__
				when 'class'
					@classes ||= []
					value = element.text.to_sym__
					raise InvalidXMLError.new "Invalid <class> value '#{value}'" unless SpellClass::ALL.include? value
					@classes << value unless @classes.include? value
				when 'castingtime'
					@casting_time = UnitType.new(element)
				when 'range'
					@range = UnitType.new(element)
				when 'duration'
					@duration = UnitType.new(element)
					@concentration = element.attributes['concentration'].nil? ? false : element.attributes['concentration']
				when 'materials'
					@materials = element.text
				when 'description'
					@description = Description.new(element)
				end
			end
			
			raise_unless_valid
		end
		
		LEVEL_NAMES = [
			'cantrip',
			'1st level',
			'2nd level',
			'3rd level',
			'4th level',
			'5th level',
			'6th level',
			'7th level',
			'8th level',
			'9th level'
		]
		
		def subtitle
			base_str = case @level
			when 0
				"#{@school.to_s.capitalize} cantrip"
			else
				"#{LEVEL_NAMES[@level]} #{@school.to_s.downcase}"
			end
			
			@ritual ? "#{base_str}, ritual" : base_str
		end
		
		def component_str
			comps = []
			comps << 'V' if @verbal
			comps << 'S' if @somatic
			comps << "M (#{@materials})" unless @materials.nil? or @materials.empty?
			comps.join ', '
		end
		
		def read_boolean_attrs(attrs)
			rit = attrs['ritual']
			ver = attrs['verbal']
			som = attrs['somatic']
			con = attrs['concentration']
			
			@ritual = rit.nil? ? false : rit.to_bool
			@verbal = ver.nil? ? false : ver.to_bool
			@somatic = som.nil? ? false : som.to_bool
			@concentration = con.nil? ? false : con.to_bool
		end
		
		def raise_unless_valid
			raise InvalidXMLError.new "No title specified" if @title.empty? or @title.nil?
			raise InvalidXMLError.new "Invalid <level> value '#{@level}'" if @level.nil? or @level < 0 or @level > 9
			raise InvalidXMLError.new "Invalid <school> value '#{@school}'" unless SpellSchool::ALL.include? @school
			raise InvalidXMLError.new "No classes specified" if @classes.empty?
			raise InvalidXMLError.new "No casting time specified" if @casting_time.nil?
			raise InvalidXMLError.new "No range specified" if @range.nil?
			raise InvalidXMLError.new "No duration specified" if @duration.nil?
		end
		
	end
	
end
