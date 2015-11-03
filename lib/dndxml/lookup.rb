#
# Author::      Jim Dovey,  jimdovey@mac.com
# Description:: Implements the DnDXML::LookupTable class.
#

require 'rexml/document'

module DnDXML
  
  class RandomRoll
    
    attr_accessor :die, :quantity, :multiplier
    
    def initialize(die, quantity, multiplier)
      @die = die
      @quantity = quantity || 1
      @multiplier = multiplier || 1
    end
    
    def to_s
      @multiplier > 1 ? "#{quantity > 1 ? @quantity : ''}d#{die}\u00D7#{@multiplier}" : "#{quantity > 1 ? @quantity : ''}d#{die}"
    end
    
    def add_to_xml_element(elem)
      elem.add_attribute 'die', @die.to_s
      elem.add_attribute 'quantity', @quantity.to_s if @quantity > 1
      elem.add_attribute 'multiplier', @multiplier.to_s if @multiplier > 1
    end
    
  end
  
  class LookupTable
    
    # Numeric attributes
    attr_accessor :die
    
    # String attributes
    attr_accessor :title
    
    # Array attributes
    attr_accessor :rows, :columns
    
    # Description
    attr_accessor :description
    
    def initialize(*args)
			case args[0]
			when REXML::Element
				load_xml(args[0])
			else
	      @die = 100
	      @rows = []
	      @columns = []
			end
    end
		
		protected
    
    def load_xml(xmlnode)
      raise ArgumentError.new("Node is not a <lookup> element") unless xmlnode.type == :element and xmlnode.name == 'lookup'
      
      @die = xmlnode.attributes['die'].to_i
			raise InvalidXMLError.new("<lookup> element must have a 'die' attribute with a numeric value") if @die.nil?
      
      xmlnode.elements.each do |element|
        case element.name
        when 'title'
          @title = element.text
        when 'description'
          @description = Description.new(element)
        when 'row'
          @rows ||= []
          rangeStart = element.attributes['startRange'].to_i
					raise InvalidXMLError.new("<row> element must have a 'startRage' attribute with a numeric value") if rangeStart.nil?
          rangeEnd = element.attributes['endRange'].to_i
					raise InvalidXMLError.new("<row> element must have an 'endRange' attribute with a numeric value") if rangeEnd.nil?
          @rows << rangeStart..rangeEnd+1
        when 'column'
          @columns ||= []
          @columns << LookupColumn.new(element)
        end
      end
    end
    
  end
  
  class LookupColumn
    
    attr_accessor :title
    attr_accessor :results
    
    def initialize(*args)
			case args[0]
			when REXML::Element
				load_xml(args[0])
			else
				@results = []
			end
    end
		
		protected
    
    def load_xml(xmlnode)
      raise ArgumentError.new("Node is not a <column> element") unless xmlnode.type == :element and xmlnode.name == 'column'
      
      @title = xmlnode.attributes['title']
			raise InvalidXMLError.new("<column> element must have a 'title' attribute") if @title.nil?
      @results = []
      
      xmlnode.elements.each do |element|
        case element.name
        when 'coinage'
          @results << CoinageResult.new(element)
        when 'item'
          @results << ItemResult.new(element)
        when 'roll'
          @results << LookupResult.new(element)
        when 'description'
          @results << DescriptionResult.new(element)
        else
          raise InvalidXMLError.new("Unexpected child element '#{element.name}' encountered while parsing <column> element tree")
        end
      end
    end
    
  end
  
  class Result
    
    attr_reader :type
    VALID_TYPES = [:coinage, :item, :lookup, :description]
    
    protected
    
    def type=(value)
      @type = value
    end
    
  end
  
  class CoinageResult < Result
    
    attr_accessor :denomination
    attr_accessor :preset_amount
    attr_accessor :random_roll
		
		def initialize
			@type = :coinage
			
			case args[0]
			when REXML::Element
				load_xml(args[0])
			when String
				@denomination = args[0]
				case args[1]
				when Numeric; @preset_amount = args[1]
				when RandomRoll; @random_roll = args[1]
				else raise ArgumentError
				end
			else
				raise ArgumentError
			end
		end
    
    def to_s
      "#{@preset_amount || @random_roll} #{denomination}"
    end
    
    def to_xml
      element = REXML::Element.new 'coinage'
      element.add_attribute 'denomination', @denomination.to_s
      element.add_attribute 'amount', @preset_amount.to_s unless @preset_amount.nil?
      @random_roll.add_to_xml_element(element) unless @random_roll.nil?
      element
    end
		
		protected
    
    def load_xml(xmlnode)
      self.type = :coinage
      @denomination = xmlnode.attributes['denomination']
			raise InvalidXMLError.new("<coinage> element must have a 'denomination' attribute") if @denomination.nil?
      if xmlnode.attributes['amount']
        @preset_amount = xmlnode.attributes['amount'].to_i
      else
        die = xmlnode.attributes['die'].to_i
        quant = xmlnode.attributes['quantity'].to_i
        mult = xmlnode.attributes['mult'].to_i
        @random_roll = RandomRoll.new(die, quant, mult)
      end
    end
    
  end
  
  class ItemResult < Result
    
    attr_accessor :item_name
    
    def initialize(*args)
			@type = :item
			
			case args[0]
			when String; @item_name = args[0]
			when REXML::Element; @name = args[0].attributes['name']
			else raise ArgumentError
			end
    end
    
    def to_s
      @name
    end
    
    def to_xml
      element = REXML::Element.new 'item'
      element.add_attribute 'name', @name
      element
    end
    
  end
  
  class LookupResult < Result
    
    attr_accessor :name, :die, :quantity
		
		def initialize(*args)
			@type = :lookup
			
			case args[0]
			when String
				raise ArgumentError unless args.count > 1
				@name = args[0]
				@die = args[1].to_i
				@quantity = args[2].to_i || 1
			when REXML::Element
	      @name = args[0].attributes['name']
	      @die = args[0].attributes['die'].to_i
	      @quantity = args[0].attributes['quantity'].to_i || 1
			end
		end
    
    def to_s
      "Roll #{@quantity > 1 ? @quantity : ''}d#{die} times on #{name}"
    end
    
    def to_xml
      element = REXML::Element.new 'roll'
      element.add_attributes 'name' => @name, 'die' => @die.to_s
      element.add_attribute 'quantity' => @quantity.to_s if @quantity > 1
    end
    
  end
  
  class DescriptionResult < Result
    
    attr_accessor :description
    
    def initialize(description)
      @type = :description
			case args[0]
			when Description; @description = args[0]
			when REXML::Element; @description = Description.new(args[0])
			end
    end
    
    def to_s
      @description.to_s
    end
    
    def to_xml
      @description.to_xml
    end
    
  end
  
end