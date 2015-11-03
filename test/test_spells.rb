require File.join(File.dirname(__FILE__), 'helper')

class TestSpells < Test::Unit::TestCase
	
	def setup
		@simple_data = read_xml_file fixture_path('simple-spell.dnd')
	end
	
	def test_spell_creation_fails_with_wrong_element
		element = REXML::Element.new('bob')
		assert_raise(ArgumentError) { Spell.new(element) }
	end
	
	def test_new_spell_default_values
		spell = Spell.new
		assert_not_nil spell
		
		assert_equal spell.verbal, false
		assert_equal spell.somatic, false
		assert_equal spell.concentration, false
		assert_equal spell.ritual, false
		assert_equal spell.school, SpellSchool::ABJURATION
		assert_equal spell.level, 0
		
		assert_equal spell.casting_time.value, 1
		assert_equal spell.casting_time.unit, 'action'
		
		assert_equal spell.range.value, 'touch'
		assert_equal spell.duration.value, 'instantaneous'
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
		assert_not_empty @simple_data
	end
	
	def test_simple_spell_content
		spell_list = @simple_data[:spells]
		assert_equal spell_list.count, 1
	end
	
	def test_simple_spell_definition
		spell = @simple_data[:spells].first
		assert_not_nil spell
		
		assert_equal spell.title, "Abi-Dalzim’s Horrid Wilting"
		assert_equal spell.level, 8
		assert_equal spell.school, SpellSchool::NECROMANCY
		
		assert spell.verbal
		assert spell.somatic
		assert_equal spell.concentration, false
		assert_equal spell.ritual, false
		
		assert_equal spell.materials, 'A bit of sponge'
		assert_equal spell.duration.to_s, 'instantaneous'
		assert_equal spell.casting_time.to_s, '1 action'
		assert_equal spell.range.to_s, '150 feet'
		
		assert_equal spell.classes.count, 2
		assert spell.classes.include?(SpellClass::SORCERER)
		assert spell.classes.include?(SpellClass::WIZARD)
		assert spell.description.to_s.start_with?('You draw the moisture from')
	end
	
end
