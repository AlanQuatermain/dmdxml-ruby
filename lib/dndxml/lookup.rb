#
# Author::      Jim Dovey,  jimdovey@mac.com
# Description:: Implements the DnDXML::LookupTable class.
#

require 'rexml/document'

module DnDXML
  
  class LookupTable
    
    # Numeric attributes
    attr_accessor :die
    
    # String attributes
    attr_accessor :title
    
    # Array attributes
    attr_accessor :rows, :columns
    
    # Description
    attr_accessor :description
    
    def initialize
      @die = 100
      @rows = []
      @columns = []
    end
    
    def initialize(xmlnode)
      raise ArgumentError.new("Node is not a <lookup> element") unless xmlnode.type == :element and xmlnode.name == 'lookup'
      
      @die = xmlnode.attributes['die'].to_i || raise InvalidXMLError.new "<lookup> element must have a 'die' attribute with a numeric value"
      
      xmlnode.elements.each do |element|
        case element.name
        when 'title'
          @title = element.text
        when 'description'
          @description = Description.new(element)
        when 'row'
          @rows ||= []
          rangeStart = element.attributes['startRange'].to_i || raise InvalidXMLError.new "<row> element must have a 'startRage' attribute with a numeric value"
          rangeEnd = element.attributes['endRange'].to_i || raise InvalidXMLError.new "<row> element must have an 'endRange' attribute with a numeric value"
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
    
    def initialize
      @results = []
    end
    
    def initialize(xmlnode)
      raise ArgumentError.new("Node is not a <column> element") unless xmlnode.type == :element and xmlnode.name == 'column'
      
      @title = xmlnode.attributes['title'] || raise InvalidXMLError.new "<column> element must have a 'title' attribute"
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
          raise InvalidXMLError.new "Unexpected child element '#{element.name}' encountered while parsing <column> element tree"
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
    
    def initialize(demonination, preset)
      self.type = :coinage
      @denomination = denomination
      @preset_amount = preset
    end
    
    def initialize(denomination, roll)
      self.type = :coinage
      @denomination = denomination
      @random_roll = roll
    end
    
    def initialize(xmlnode)
      self.type = :coinage
      @denomination = xmlnode.attributes['denomination'] || raise InvalidXMLError.new "<coinage> element must have a 'denomination' attribute"
      if xmlnode.attributes['amount']
        @preset_amount = xmlnode.attributes['amount'].to_i
      else
        die = xmlnode.attributes['die'].to_i
        quant = xmlnode.attributes['quantity'].to_i
        mult = xmlnode.attributes['mult'].to_i
        @random_roll = RandomRoll.new(die, quant, mult)
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
    
  end
  
  class ItemResult < Result
    
    attr_accessor :item_name
    
    def initialize(name)
      self.type = :item
      @item_name = name
    end
    
    def initialize(xmlnode)
      self.type = :item
      @name = xmlnode.attributes['name']
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
    
    def initialize(name, die, quantity)
      self.type = :lookup
      @name = name
      @die = die
      @quantity = quantity || 1
    end
    
    def initialize(xmlnode)
      self.type = :lookup
      @name = xmlnode.attributes['name']
      @die = xmlnode.attributes['die'].to_i
      @quantity = xmlnode.attributes['quantity'].to_s || 1
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
      self.type = :description
      @description = description
    end
    
    def initialize(xmlnode)
      self.type = :description
      @description = Description.new(xmlnode)
    end
    
    def to_s
      @description.to_s
    end
    
    def to_xml
      @description.to_xml
    end
    
  end
  
  class RandomRoll
    
    attr_accessor :die, :quantity, :multiplier
    
    def initialize(die, quantity, multiplier)
      @die = die
      @quantity = quantity || 1
      @multiplier = multiplier || 1
    end
    
    def to_s
      @multiplier > 1 ? "#{quantity > 1 @quantity : ''}d#{die}\u00D7#{@multiplier}" : "#{quantity > 1 ? @quantity : ''}d#{die}"
    end
    
    def add_to_xml_element(elem)
      elem.add_attribute 'die', @die.to_s
      elem.add_attribute 'quantity', @quantity.to_s if @quantity > 1
      elem.add_attribute 'multiplier', @multiplier.to_s if @multiplier > 1
    end
    
  end
  
end