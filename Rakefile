require 'rubygems'
require 'hoe'
require './lib/dndxml.rb'

# Install Hoe rubygem first:
#  sudo gem install hoe --include-dependencies

Hoe.spec('dndxml') do
	developer 'Jim Dovey', 'jimdovey@mac.com'
	@summary = 'Ruby library for processing DnD XML data.'
	@version = DnDXML::VERSION
	@url = File.read_utf('README.txt').match(/(http:\/\/.+)\s/)[1].strip
	@extra_deps << ['mocha', '~> 0.9.8']
end

desc "Open an irb session preloaded with this library"
task :console do
	sh "irb -rubygems -r ./lib/dndxml.lib"
end

task :default => [:test_units]

desc "Run test suite"
Rake::TestTask.new("test_units") do |t|
	t.pattern = 'test/test_*.rb'
	t.verbose = false
end

desc "Generate test coverage data"
task :coverage do
	system "rm -rf coverage"
	system "rcov test/test_*.rb"
	system "open coverage/index.html"
end

desc "Build the Manifest.txt file based on the contents of the local git repository"
task :build_manifest do
	str = `git ls-files`
	File.open('Manifest.txt', 'w') do |file|
		str.each_line do |line|
			file.write(line) unless line =~ /^\.gitignore/
		end
	end
end

# This is just an EXAMPLE-- it will NOT work without a valid account/project at Rubyforge
# desc "Upload site to Rubyforge"
# task :site do
# 	sh "scp -r doc/* jim@alanquatermain.rubyforge.org:/var/www/gforge-projects/dndxml"
# end