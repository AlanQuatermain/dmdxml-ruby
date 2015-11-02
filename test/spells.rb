require File.join(File.dirname(__FILE__), 'helper')

class TestSpells < Test::Unit::TestCase
	
	def setup
		@simple_data = read_xml_file fixture_path('simple-spell.dnd')
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
		
		assert_true spell.verbal
		assert_true spell.somatic
		assert_false spell.concentration
		assert_false spell.ritual
		
		assert_equal spell.materials, 'A bit of sponge'
		assert_equal spell.duration.to_s, 'instantaneous'
		assert_equal spell.casting_time.to_s, '1 action'
		assert_equal spell.range.to_s, '150 feet'
		
		assert_equal spell.classes.count, 2
		assert_true spell.classes.contains?(SpellClass::SORCERER)
		assert_true spell.classes.contains?(SpellClass::WIZARD)
		assert_true spell.description.to_s.start_with?('You draw the moisture from')
	end
	
end
