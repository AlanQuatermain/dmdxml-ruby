require File.join(File.dirname(__FILE__), 'helper')

class TestSpells < Test::Unit::TestCase
	
	def read_simple_spell
		read_xml_file fixture_path('simple-spell.dnd')
	end
	
	def read_double_spell
		read_xml_file fixture_path('two-spells.dnd')
	end
	
	def read_ritual_spell
		read_xml_file fixture_path('ritual-spell.dnd')
	end
	
	def test_spell_creation_fails_with_wrong_element
		element = REXML::Element.new('bob')
		assert_raise(ArgumentError) { Spell.new(element) }
	end
	
	def test_new_spell_default_values
		spell = Spell.new
		assert_not_nil spell
		
		assert_equal false, spell.verbal
		assert_equal false, spell.somatic
		assert_equal false, spell.concentration
		assert_equal false, spell.ritual
		assert_equal SpellSchool::ABJURATION, spell.school
		assert_equal 0, spell.level
		
		assert_equal 1, spell.casting_time.value
		assert_equal 'action', spell.casting_time.unit
		
		assert_equal 'touch', spell.range.value
		assert_equal 'instantaneous', spell.duration.value
	end
	
	def make_test_spell
		spell = Spell.new
		
		spell.title = 'Test Spell'
		spell.somatic = true
		spell.school = SpellSchool::EVOCATION
		spell.classes << SpellClass::SORCERER
		spell.classes << SpellClass::WARLOCK
		spell.classes << SpellClass::WIZARD
		spell.level = 2
		spell.range = Spell::UnitType.new(60, 'foot')
		spell.description = Description.new
		spell.description.elements << Paragraph.new('This is a test spell.')
		spell.description.elements << Paragraph.new('It is rather lovely.')
		spell
	end
	
	def test_create_spell_str
		spell = make_test_spell
		assert_not_nil spell
		
		str = spell.to_s
		expected = %q{Test Spell
2nd level evocation
Sorcerer / Warlock / Wizard
Casting time: 1 action
Range: 60 feet
Components: S
Duration: instantaneous
This is a test spell.
It is rather lovely.

}
		assert_equal expected, str
	end
	
	def test_simple_spell_loads
		assert_not_empty read_simple_spell
	end
	
	def test_simple_spell_content
		spell_list = read_simple_spell[:spells]
		assert_equal 1, spell_list.count
		
		spell_list = read_double_spell[:spells]
		assert_equal 2, spell_list.count
	end
	
	def test_simple_spell_definition
		spell = read_simple_spell[:spells].first
		assert_not_nil spell
		
		assert_equal "Abi-Dalzim’s Horrid Wilting", spell.title
		assert_equal 8, spell.level
		assert_equal SpellSchool::NECROMANCY, spell.school
		
		assert spell.verbal
		assert spell.somatic
		assert_equal false, spell.concentration
		assert_equal false, spell.ritual
		
		assert_equal 'A bit of sponge', spell.materials
		assert_equal 'instantaneous', spell.duration.to_s
		assert_equal '1 action', spell.casting_time.to_s
		assert_equal '150 feet', spell.range.to_s
		
		assert_equal 2, spell.classes.count
		assert spell.classes.include?(SpellClass::SORCERER)
		assert spell.classes.include?(SpellClass::WIZARD)
		assert spell.description.to_s.start_with?('You draw the moisture from')
	end
	
	def test_ritual_loads
		assert_not_empty read_ritual_spell
	end
	
	def test_ritual_spell_definition
		spell = read_ritual_spell[:spells].first
		assert_not_nil spell
		
		assert_equal 'Alarm', spell.title
		assert_equal 1, spell.level
		assert_equal SpellSchool::ABJURATION, spell.school
		
		assert spell.verbal
		assert spell.somatic
		assert spell.ritual
		assert !spell.concentration
		
		assert_equal 'A tiny bell and a piece of fine silver wire', spell.materials
		assert_equal '1 minute', spell.casting_time.to_s
		assert_equal '30 feet', spell.range.to_s
		assert_equal '8 hours', spell.duration.to_s
		
		assert_equal 2, spell.classes.count
		assert spell.classes.include?(SpellClass::RANGER)
		assert spell.classes.include?(SpellClass::WIZARD)
		assert spell.description.to_s.start_with?('You set an alarm against unwanted intrusion.')
	end
	
end
