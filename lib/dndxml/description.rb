#
# Author::      Jim Dovey,  jimdovey@mac.com
# Description:: Implements the DnDXML::Description class, and the associated Table and Callout
#               classes used within Descriptions.
#

require 'rexml/document'

module DnDXML
	
	class Description
		attr_accessor :elements	# Paragraph, List, Table, Callout, Footnote
		
		def initialize
			@elements = []
		end
		
		def initialize(xmlnode)
			raise ArgumentError.new("Input is not a <description> element") unless xmlnode.node_type == :element and xmlnode.name == 'description'
			
			@elements = []
			
			xmlnode.elements.each do |element|
				case element.name
				when 'p'
					@elements << Paragraph.new(element)
				when 'list'
					@elements << List.new(element)
				when 'table'
					@elements << Table.new(element)
				when 'callout'
					@elements << Callout.new(element)
				end
			end
		end
		
		def to_xml
			element = REXML::Element.new('description')
			@elements.each do |subelement|
				element.add_element subelement.to_xml
			end
			element
		end
		
		def to_s
			@elements.map(&:to_s).join('')
		end
	end
	
	class List
		attr_accessor :items
		attr_accessor :list_type
		
		VALID_TYPES = [:indent, :bullet, :number, :letter, :small, :roman, :smallroman]
		
		def initialize
			@elements = []
		end
		
		def initialize(xmlnode)
			@elements = []
			
			t = xmlnode.attributes['type'].to_sym
			@list_type = VALID_TYPES.contains? t ? t : :indent
			
			xmlnode.elements.each do |element|
				case element.name
				when 'listitem'
					@elements << ListItem.new(element)
				when 'footnote'
					@elements << Footnote.new(element)
				else
					raise InvalidXMLError.new "Unexpected element <#{element.name}> encountered within a list"
				end
			end
		end
		
		def to_xml
			element = REXML::Element.new('list', {:type => @list_type.to_s})
			@items.each do |item|
				element.add_element item.to_xml
			end
			element.add_element @footnote.to_xml unless @footnote.nil?
		end
		
		def to_s
			str = ''
			@items.each do |item|
				str << " - #{item.to_s}"
			end
			str << "  #{@footnote.to_s}"
		end
	end
	
	class ListItem < Text
		def to_xml
			element = REXML::Element.new 'listitem'
			xml_nodes.each { |node| element << node }
			element
		end
	end
	
	class Table
		attr_accessor :title
		attr_accessor :header_row
		attr_accessor :rows
		attr_accessor :footnotes
		
		def initialize
			@rows = []
			@footnotes = []
		end
		
		def initialize(xmlnode)
			raise ArgumentError.new("Input is not a <table> element") unless xmlnode.node_type == :element and xmlnode.name == 'table'
			
			xmlnode.elements.each do |element|
				case element.name
				when 'title'
					@title = element.text
				when 'header'
					@header_row = TableRow.new(element)
				when 'row'
					@rows ||= []
					@rows << TableRow.new(element)
				when 'footnote'
					@footnotes ||= []
					@footnotes << Footnote.new(element)
				end
			end
		end
		
		def to_xml
			element = REXML::Element.new 'table'
			element.add_element('title').add_text(@title) if @title
			element << @header_row.to_xml if @header_row
			@rows.each { |row| element << row.to_xml }
			@footnodes.each { |fn| element << fn.to_xml }
		end
		
		def to_s
			str = @title || "\n"
			str << "#{@header_row.to_s}\n" unless @header_row.nil? or @header_row
			@rows.each { |row| str << "#{row.to_s}\n" }
			@footnotes.each { |fn| str << "#{fn.to_s}\n" }
			str
		end
	end
	
	class TableRow
		attr_accessor :cells			# array of TableCell
		
		def initialize(is_header=false)
			@cells = []
			@is_header = is_header
		end
		
		def initialize(xmlnode)
			raise ArgumentError.new("Input is not a <header> or <row> element") unless xmlnode.node_type == :element and (xmlnode.name == 'header' or xmlnode.name == 'row')
			
			@is_header = case xmlnode.name
			when 'header' then true
			when 'row' then false
			end
			
			@cells = []
			xmlnode.elements.each do |element|
				raise InvalidXMLError.new("<header> and <row> elements may only contain <cell> elements") unless element.name == 'cell'
				@cells << TableCell.new(element)
			end
		end
		
		def to_xml
			element = REXML::Element.new @is_header ? 'header' : 'row'
			@cells.each { |node| element << node.to_xml }
		end
		
		def to_s
			values = case @is_header
			when true
				@cells.map { |v| " *#{v.to_s}* " }
			else
				@cells.map { |v| " #{v.to_s} " }
			end
			values.join "|"
		end
	end
	
	class TableCell < Text
		def to_xml
			xml_in_element 'cell'
		end
	end
	
	class Text
		attr_accessor :plain_text
		attr_accessor :attributes
		
		ATTRIBUTES = [:em, :ref, :fn]
		
		def initialize(text)
			@plain_text = text
			@attributes = []
		end
		
		def initialize(xmlnode)
			xmlnode.each do |node|
				case node.node_type
				when :element
					append_text node.text, node.title.to_sym
				when :text
					append_text node.value
				end
			end
		end
		
		def add_attribute(type, start, length)
			@attributes << {:type => type, :start => start, :length => length}
		end
		
		def append_text(text, type=nil)
			current = @plain_text.length
			@plain_text << text
			add_attribute(type, current, text.length) unless type.nil? or !ATTRIBUTES.contains?(type)
		end
		
		def to_s
			@plain_text
		end
		
		protected
		
		def xml_nodes
			nodes = []
			cursor = 0
			@attributes.each do |a|
				nodes << REXML::Text.new(@plain_text[cursor..a[:start]-1], true)
				attr_text = @plain_text[a[:start], a[:length]]
				nodes << REXML::Element.new(a[:type].to_s).add_text(attr_text)
				cursor = a[:start] + a[:length]
			end
			nodes
		end
		
		def xml_in_element(name)
			raise ArgumentError.new "'name' cannot be nil or empty" if name.nil? or name.empty?
			element = REXML::Element.new name
			xml_nodes.each { |node| element << node }
			element
		end
	end
	
	class Paragraph < Text
		def initialize(xmlnode)
			raise ArgumentError.new("Input is not a <p> element") unless xmlnode.node_type == :element and xmlnode.name == 'p'
			super
		end
		
		def to_xml
			xml_in_element 'p'
		end
		
		def to_s
			super + "\n"
		end
	end
	
	class Footnote < Text
		attr_accessor :mark
		
		def initialize
			@mark = '*'
			super
		end
		
		def initialize(xmlnode)
			@mark = xmlnode.attributes['mark']
			super
		end
		
		def to_xml
			element = nodes_in_element 'footnote'
			element.add_attribute 'mark', @mark
			element
		end
	end
	
	class Callout < Description
		attr_accessor :title
		
		def initialize(xmlnode)
			def initialize(xmlnode)
				raise ArgumentError.new("Input is not a <callout> element") unless xmlnode.node_type == :element and xmlnode.name == 'callout'
			
				xmlnode.elements.each do |element|
					case element.name
					when 'title'
						@title << element.text
					when 'p'
						@elements << Paragraph.new(element)
					when 'list'
						@elements << List.new(element)
					when 'table'
						@elements << Table.new(element)
					when 'callout'
						@elements << Callout.new(element)
					when 'footnote'
						@elements << Footnote.new(element)
					end
				end
			end
		end
		
		def to_xml
			element = super
			element.name = 'callout'
			return element if @title.nil?
			
			title_element = REXML::Element.new('title')
			title_element.text = @title
			element.insert_before(element[0], title_element)
			
			element
		end
		
		def to_s
			str = @title ? "#{@title}\n" : ''
			str << super
			str
		end
	end
	
end
