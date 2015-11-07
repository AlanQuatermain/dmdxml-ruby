#
# Author::      Jim Dovey,  jimdovey@mac.com
# Description:: Implements extensions to the String class.
#

# Some extensions to the String class to assist the parser.
class String
	
	#
	# Interprets the current string as a boolean. It uses a case-insensitive comparison,
	# so the allowed values below can be in any case.
	#
	# ==== Supported values
	# true::   'true', 'yes', 't', 'y'
	# false::  'false', 'no', 'f', 'n'
	#
	def to_bool
		return false if self =~ /(^false$)|(^no$)|(^f$)|(^n$)/i
		return true if self =~ /(^true$)|(^yes$)|(^t$)|(^y$)/i
		return nil
	end
	
	#
	# Converts a string to title-case.
	#
	def titlecase
		split(/(\W)/).map(&:capitalize).join
	end
	
	def to_sym__
		tr(' ', '_').to_sym
	end
	
	#
	# Tests whether a string is a representation of a number.
	#
	def number?
		true if Float(string) rescue false
	end
	
end