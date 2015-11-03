#
# Author::      Jim Dovey,  jimdovey@mac.com
# Description:: Implements the DnDXML::Creature class.
#

require 'rexml/document'

module DnDXML
	
	module CreatureType
		ABERRATION = :aberration
		BEAST = :beast
		CELESTIAL = :celestial
		CONSTRUCT = :construct
		DRAGON = :dragon
		ELEMENTAL = :elemental
		FEY = :fey
		FIEND = :fiend
		GIANT = :giant
		HUMANOID = :humanoid
		MONSTROSITY = :monstrosity
		OOZE = :ooze
		PLANT = :plant
		UNDEAD = :undead
		
		ALL = [ABERRATION, BEAST, CELESTIAL, CONSTRUCT, DRAGON, ELEMENTAL, FEY, FIEND, GIANT, HUMANOID, MONSTROSITY, OOZE, PLANT, UNDEAD]
	end
	
	module CreatureSize
		TINY = :tiny
		SMALL = :small
		MEDIUM = :medium
		LARGE = :large
		HUGE = :huge
		GARGANTUAN = :gargantuan
		
		ALL = [TINY, SMALL, MEDIUM, LARGE, HUGE, GARGANTUAN]
	end
	
	module Alignment
		LAWFUL_GOOD = :lawful_good
		NEUTRAL_GOOD = :neutral_good
		CHAOTIC_GOOD = :chaotic_good
		LAWFUL_NEUTRAL = :lawful_neutral
		NEUTRAL = :neutral
		CHAOTIC_NEUTRAL = :chaotic_neutral
		LAWFUL_EVIL = :lawful_evil
		NEUTRAL_EVIL = :neutral_evil
		CHAOTIC_EVIL = :chaotic_evil
	end
	
	module Skill
		ACROBATICS = :acrobatics
		ANIMAL_HANDLING = :animal_handling
		ARCANA = :arcana
		ATHLETICS = :athletics
		DECEPTION = :deception
		HISTORY = :history
		INSIGHT = :insight
		INTIMIDATION = :intimidation
		INVESTIGATION = :investigation
		MEDICINE = :medicine
		MATURE = :nature
		PERCEPTION = :perception
		PERFORMANCE = :performance
		PERSUASION = :persuasion
		RELIGION = :religion
		SLEIGHT_OF_HAND = :sleight_of_hand
		STEALTH = :stealth
		SURVIVAL = :survival
		
		ALL = [ACROBATICS, ANIMAL_HANDLING, ARCANA, ATHLETICS, DECEPTION, HISTORY, INSIGHT, INTIMIDATION, INVESTIGATION, MEDICINE, MATURE, PERCEPTION, PERFORMANCE, PERSUASION, RELIGION, SLEIGHT_OF_HAND, STEALTH, SURVIVAL]
	end
	
	class LegendaryAction
		attr_accessor :cost, :description
		
		def initialize(*args)
			@description = []
			
			case args[0]
			when REXML::Node, REXML::Element
				@cost = xmlnode.attributes['cost'].to_i
				@description = xmlnode.elements.map { |e| Paragraph.new(e) }
			when Numeric
				@cost = args[0]
				case args[1]
				when String; @description = [Paragraph.new(args[1])]
				when Paragraph; @description = [args[1]]
				when Array; @description = args[1].filter { |p| p.kind_of? Paragraph }
				else raise ArgumentError
				end
			else
				raise ArgumentError
			end
		end
		
		def to_s
			"#{@cost} - #{@description.to_s}"
		end
		
		def to_xml
			element = REXML::Element.new 'action'
			element.add_attribute 'cost', @cost
			if @description.kind_of? Array
				@description.each { |e| element << e.to_xml }
			else
				element << @description.to_xml
			end
			element
		end
	end
	
	class Creature
		
		# Symbol values
		attr_accessor :type, :size, :alignment
		
		# String values
		attr_accessor :title, :subtype, :hit_point_roll, :armor_type, :hit_points
		
		# Numeric values
		attr_accessor :armor_class, :challenge, :xp, :legendary_action_count, :passive_perception
		
		# Hashes {name => value/modifier}
		attr_accessor :skills, :stats, :saving_throws, :speeds, :senses
		
		# Arrays
		attr_accessor :languages, :traits, :actions, :reactions, :legendary_actions, :damage_vulnerability, :damage_resistance, :damage_immunity, :condition_immunity
		
		# Description
		attr_accessor :description
		
		def initialize(*args)
			case args[0]
			when REXML::Element
				load_xml(args[0])
			else
				@skills = {}
				@stats = {}
				@saving_throws = {}
				@speeds = {}
				@senses = {}
				@traits = []
				@actions = []
				@reactions = []
				@legendary_actions = []
				@damage_vulnerability = []
				@damage_resistance = []
				@damage_immunity = []
				@condition_immunity = []
			end
		end
		
		def subtitle
			str = "#{@size.to_s.capitalize} #{@type.to_s__.lowercase}"
			str << " (#{@subtype})" unless @subtype.nil? or @subtype.empty?
			str << ", #{@alignment.to_s__.lowercase}"
		end
		
		def to_xml
			root = REXML::Element.new 'creature'
			
			root.add_attribute('size', @size)
			root.add_attribute('type', @type)
			root.add_attribute('subtype', @subtype) unless @subtype.empty?
			
			root.add_element('title').add_text(@title)
			acelem = root.add_element('ac').add_text(@ac.to_s)
			acelem.add_attribute('type', @armor_type) unless @armor_type.empty?
			
			root.add_element('hp').add_text(@hit_points).add_attribute('roll', @hit_point_roll)
			
			spd = root.add_element('speed').add_text(@speeds[:walk].to_s)
			@speeds.each do |name, value|
				next if name == :walk
				if name == :hover
					spd.add_attribute('fly', value.to_s)
					spd.add_attribute('hover', 'true')
				else
					spd.add_attribute(name.to_s, value.to_s)
				end
			end
			
			stat = root.add_element 'statblock'
			@stats.each { |key, value| stat.add_attribute(key.to_s, value.to_s) }
			
			@damage_vulnerability.each { |e| root.add_element('vulnerable').add_text(e) }
			@damage_resistance.each { |e| root.add_element('dmgresist').add_text(e) }
			@damage_immunity.each { |e| root.add_element('dmgimmune').add_text(e) }
			@condition_immunity.each { |e| root.add_element('statimmune').add_text(e) }
			
			sen = root.add_element 'senses', 'perception' => @passive_perception.to_s
			@senses.each { |name, value| sen.add_element('sense', 'name' => name).add_text(value.to_s) }
			
			@languages.each { |e| root.add_element('language').add_text(e) }
			
			root.add_attribute('challenge', 'xp' => @xp.to_s).add_text(@challenge_rating.to_s)
			
			unless @traits.empty?
				r = root << 'traits'
				@traits.each do |trait|
					t = r << 'trait'
					trait.each { |e| t << e.to_xml }
				end
			end
			
			unless @actions.empty?
				r = root << 'actions'
				@actions.each do |action|
					t = r << 'action'
					action.each { |e| t << e.to_xml }
				end
			end
			
			unless @reactions.empty?
				r = root << 'reactions'
				@reactions.each do |action|
					t = r << 'action'
					action.each { |e| t << e.to_xml }
				end
			end
			
			unless @legendary_actions.empty?
				r = root.add_element 'legendaryactions', 'available' <= @legendary_action_count.to_s
				@legendary_actions.each { |e| r << e.to_xml }
			end
		end
		
		def to_s
			str = "#{@title}\n"
			str << "#{subtitle}\n"
			
			str << "------------------\n"
			
			str << "Armor Class #{@armor_class}"
			str << " (#{@armor_type})" unless @armor_type.empty?
			str << "\n"
			
			str << "Hit Points #{@hit_points} (#{@hit_point_roll})\n"
			
			str << "Speed #{@speeds[:walk]} ft."
			str << ", fly #{@speeds[:fly]} ft." if @speeds.has_key? :fly
			str << ", fly #{@speeds[:hover]} ft. (hover)" if @speeds.has_key? :hover
			str << ", spiderclimb #{@speeds[:spiderclimb]} ft." if @speeds.has_key? :spiderclimb
			str << ", swim #{@speeds[:swim]} ft." if @speeds.has_key? :swim
			str << "\n"
			
			str << "------------------\n"
			
			@stats.each { |name, value| str << "#{name.to_s__.uppercase} : #{value} (#{signed_str modifier(name)})\n" }
			
			str << "------------------\n"
			
			unless @saving_throws.empty?
				str << "Saving Throws "
				values = []
				@saving_throws.each { |stat, value| values << "#{stat.to_s.capitalize} +#{value}" }
				str << values.join(', ')
				str << "\n"
			end
			
			unless @skills.empty?
				str << "Skills "
				values = []
				@skills.each { |skill, value| values << "#{skill.to_s__.capitalize} #{signed_str value}\n" }
				str << values.join(', ')
				str << "\n"
			end
			
			unless @damage_vulnerability.empty?
				str << "Damage Vulnerabilities #{@damage_vulnerability.map { |e| e.lowercase }.join(', ')}\n"
			end
			
			unless @damage_resistance.empty?
				str << "Damage Resistances #{@damage_resistance.map { |e| e.lowercase }.join('; ')}\n"
			end
			
			unless @damage_immunity.empty?
				str << "Damage Immunities #{@damage_immunity.map { |e| e.lowercase }.join(', ')}\n"
			end
			
			unless @condition_immunity.empty?
				str << "Condition Immunities #{@condition_immunity.map { |e| e.lowercase }.join(', ')}\n"
			end
			
			str << "Senses "
			@senses.each { |name, value| str << "#{name.lowercase} #{@value} ft., " }
			str << "passive Perception #{@passive_perception}\n"
			
			str << "Languages "
			if @languages.empty?
				str << "—"
			else
				str << @languages.join(', ')
			end
			str << "\n"
			
			str << "Challenge #{@challenge_rating} (#{@xp.to_nice_str})"
			
			str << "------------------\n\n"
			
			unless @traits.empty?
				str << @traits.map { |trait| trait.to_s }.join("\n\n")
			end
			
			unless @actions.empty?
				str << "ACTIONS\n"
				str << "------------------\n\n"
				str << @actions.map { |action| action.to_s }.join("\n\n")
			end
			
			unless @reactions.empty?
				str << "REACTIONS\n"
				str << "------------------\n\n"
				str << @reactions.map { |action| action.to_s }.join("\n\n")
			end
			
			unless @legendary_actions.empty?
				str << "LEGENDARY ACTIONS\n"
				str << "------------------\n\n"
				str << "The #{@title.lowercase} can take #{@legendary_action_count} legendary actions, using the options below. It can take only one legendary action at a time, and only at the end of another creature's turn. Spent legendary actions are regained at the start of its turn.\n\n"
				str << @legendary_actions.map { |action| action.to_s }.join("\n\n")
			end
		end
		
		def modifier(key)
			case key
			when :str, :dex, :con, :int, :wis, :cha
				((@stats[key] - 10) / 2).floor
			end
			0
		end
		
		protected
		
		def load_xml(xmlnode)
			raise ArgumentError.new("Input is not a <creature> element") unless xmlnode.node_type == :element and xmlnode.name == 'creature'
			
			@type = xmlnode.attributes['type'].to_sym
			@size = xmlnode.attributes['size'].to_sym
			@subtype = xmlnode.attributes['subtype']
			raise InvalidXMLError.new "Unknown type '#{@type}'" unless CreatureType::ALL.include?(@type)
			raise InvalidXMLError.new "Unknown size '#{@size}'" unless CreatureSize::ALL.include?(@size)
			
			xmlnode.elements.each do |element|
				case element.name
				when 'title'
					@title = element.text
				when 'alignment'
					@alignment = element.text.to_sym
					raise InvalidXMLError.new "Unknown alignment '#{element.text}'" unless Alignment::ALL.include?(@alignment)
				when 'ac'
					@armor_class = element.text.to_i
					raise InvalidXMLError.new "Invalid armor class '#{element.text}'" if @armor_class.nil?
					@armor_type = element.attributes['type']
				when 'hp'
					@hit_points = element.text
					raise InvalidXMLError.new "Invalid hit point maximum '#{element.text}'" if @hit_points.nil?
					@hit_point_roll = element.attributes['roll']
				when 'speed'
					@speeds ||= {}
					is_hover = element.attributes['hover']
					fly = element.attributes['fly'] if element.attributes.has_key? 'fly'
					@speeds[:walk] = element.text.to_i
					@speeds[:swim] = element.attributes['swim'] if element.attributes.has_key? 'swim'
					@speeds[:spiderclimb] = element.attributes['spiderclimb'] if element.attributes.has_key? 'spiderclimb'
					
					unless fly.nil?
						if is_hover == 'true'
							@speeds[:hover] = fly
						else
							@speeds[:fly] = fly
						end
					end
				when 'statblock'
					@stats ||= {}
					element.attributes.each { |name, value| @stats[name.to_sym] = value.to_i }
				when 'saves'
					@saving_throws ||= {}
					element.attributes.each { |name, value| @saving_throws[name.to_sym__] = value.to_i }
				when 'skill'
					@skills ||= {}
					@skills[element.attributes['name'].to_sym__] = element.text.to_i
				when 'vulnerable'
					@damage_vulnerability ||= []
					@damage_vulnerability << element.text
				when 'dmgresist'
					@damage_resistance ||= []
					@damage_resistance << element.text
				when 'dmgimmune'
					@damage_immunity ||= []
					@damage_immunity << element.text
				when 'statimmune'
					@condition_immunity ||= []
					@condition_immunity << element.text
				when 'senses'
					@passive_perception = element.attributes['perception'].to_i
					@senses ||= {}
					element.elements.each { |sub| @senses[sub.attributes['name']] = sub.text.to_i }
				when 'language'
					@languages ||= []
					@languages << element.text
				when 'challenge'
					@challenge = element.text
					@xp = element.attributes['xp'].to_i
				when 'traits'
					@traits ||= []
					@traits << element.elements.map { |p| Paragraph.new(p) }
				when 'actions'
					@actions ||= []
					@actions << element.elements.map { |p| Paragraph.new(p) }
				when 'reactions'
					@reactions ||= []
					@reactions << element.elements.map { |p| Paragraph.new(p) }
				when 'legendaryactions'
					@legendary_actions ||= []
					@legendary_actions << element.elements.map { |e| LegendaryAction.new(e) }
					@legendary_action_count = element.attributes['available'].to_i
				when 'description'
					@description = Description.new(element)
				end
			end
		end
		
		private
		
		def signed_str(value)
			value < 0 ? "#{value}" : "+#{value}"
		end
		
	end
	
end