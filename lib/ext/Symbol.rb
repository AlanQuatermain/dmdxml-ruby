#
# Author::      Jim Dovey,  jimdovey@mac.com
# Description:: Implements extensions to the String class.
#

# Some extensions to the Symbol class to assist the parser.
class Symbol
	
	def to_s__
		to_s.tr '_', ' '
	end
	
end