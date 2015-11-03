# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
	s.name = %q{dndxml}
	s.version = "0.1"
	
	s.required_rubygems_version = Gem::requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
	s.authors = ["Jim Dovey"]
	s.date = %q{2015-11-02}
	s.description = %q{DnD-XML provides a suite of classes representing common DnD statistic types (magic items, creatures, spells, and lookup tables) and their representation in XML. It supports reading, writing, and editing XML format files.}
	s.email = ["jimdovey@mac.com"]
	s.extra_rdoc_files = ['History.txt', 'Manifest.txt', 'README.txt']
	s.files = ['History.txt', 'Manifest.txt' 'README.txt', 'Rakefile', 'lib/ext/string.rb', 'lib/ext/NilClass.rb', 'lib/ext/Number.rb', 'lib/ext/Symbol.rb', 'lib/dndxml.rb', 'lib/dndxml/creature.rb', 'lib/dndxml/description.rb', 'lib/dndxml/item.rb', 'lib/dndxml/lookup.rb', 'lib/dndxml/spell.rb', 'lib/dndxml/xmlreader.rb', 'lib/dndxml/xmlwriter.rb', 'resources/datatypes.rnc', 'resources/dnd.rnc', 'text/fixtures/simple-spell.dnd', 'test/helper.rb', 'test/suite.rb', 'test/spells.rb']
	s.homepage = %q{http://alanquatermain.me/dndxml}
	s.rdoc_options = ['--main', 'README.txt']
	s.require_paths = ['lib']
	s.rubyforge_project = %q{dndxml}
	s.rubygems_version = %q{2.0.14}
	s.summary = %q{Ruby interface to Dungeons & Dragons XML data.}
	s.test_files = ['test/test_spells.rb']
	
	if s.respond_to? :specification_version then
		current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
		s.specification_version = 3
		
		if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
			s.add_development_dependency(%q<mocha>, ['~> 1.1.0'])
			s.add_development_dependency(%q<hoe>, ['~> 3.14.2'])
		else
			s.add_dependency(%q<mocha>, ['~> 1.1.0'])
			s.add_dependency(%q<hoe>, ['~> 3.14.2'])
		end
	else
		s.add_dependency(%q<mocha>, ['~> 1.1.0'])
		s.add_dependency(%q<hoe>, ['~> 3.14.2'])
	end
end