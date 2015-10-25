#
# Author::      Jim Dovey,  jimdovey@mac.com
# Description:: Implements extensions to the Number class.
#

# Some extensions to the Number class for presentation.
class Number
	
	def to_nice_str
		parts.join '.'
	end
	
	private
	
	NUM_DELIMITER_REGEX = /(\d)(?=(\d\d\d)+(?!\d))/
	
	def parts
		left, right = to_s.split('.')
		left.gsub!(NUM_DELIMITER_REGEX) do |digit_to_delimit|
			"#{digit_to_delimit},"
		end
		[left, right].compact
	end
	
end