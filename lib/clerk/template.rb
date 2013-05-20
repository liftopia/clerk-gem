module Clerk
  ##
  # Template DSL for creating transformation templates which define
  # how lines of data are transformed into a structure by Clerk
  class Template
    def initialize
      @template_array = []
    end

    def to_a
      @template_array
    end

    ##
    # Add a named parameter to the template.
    #
    # The named parameter represents a keyed element within the
    # final data structure. For example, suppose there is a line
    # of data containing a single element, hello, and you want to 
    # transform that line to be a hash with the first key being
    # :message, you can use the named parameter as follows:
    #
    #   template = Clerk::Template.new
    #   template.named :message
    #
    # The resulting template will assign the first position to the
    # key :message in the resulting transformed hash.
    #
    # * *Args* :
    #   - +key+ -> the key value for this named element (String or Symbol)
    #   - +options+ -> hash of options, ex., {:position => 3}
    # * *Returns* :
    #   - current template array
    # * *Raises* :
    #   - +Clerk::GroupedNotLastError+ -> if there is a grouped element in the template
    #   - +TypeError+ -> if the position option is not an integer or is less than 1
    def named(key, options = {})
      raise GroupedNotLastError if has_grouped_element?
      if options.has_key? :position
        raise TypeError, "'#{options[:position]}' is not an integer" unless options[:position].is_a? Integer

        position = options[:position] - 1
        raise IndexError, "Position #{options[:position]} is invalid" if position < 0

        @template_array[position] = key
      else
        @template_array << key
      end
    end

    ##
    # Ignore the data element in the corresponding position
    #
    # If a specific piece of data within a given data line should be
    # discarded on transformation, the ignored directive should be
    # used to ignore it in the resulting structure.
    #
    # * *Returns* :
    #   - current template array
    # * *Raises* :
    #   - +Clerk::GroupedNotLastError+ -> if there is a grouped element in the template
    def ignored
      raise GroupedNotLastError if has_grouped_element?
      @template_array << nil
    end

    ##
    # Helper method to see if a grouped element is in the template
    #
    # This is mainly used to verify that the grouped element is the
    # last one added to the template. This might change in the future
    # but Clerk currently doesn't support grouped elements followed
    # by other elements
    def has_grouped_element?
      @template_array.any? { |i| i.kind_of? Hash }
    end

    ##
    # Group the next n elements into a named group
    #
    # This template option is used when you have data that should
    # be grouped into chunks. For example, if you have data that
    # represents pairs of information like quantity and price of
    # items you can use the grouped option to collect them into
    # logical groups.
    #
    # Suppose the data looks as follows.
    #
    #   [ "29.99", 10, "19.95", 100 ]
    #
    # Using the following template will result in the hash that
    # follows the template.
    #
    #   template = Clerk::Template.new
    #   template.grouped :items, [ :price, :quantity ]
    #
    #   { :items => [
    #     { :price => "29.99", :quantity => 10  } ,
    #     { :price => "19.95", :quantity => 100 } ,
    #   ]}
    #
    # * *Args* :
    #   - +name+ -> the name to assign to the group, ex., +:logins+
    #   - +groups+ -> grouped element names, ex., +[:date, :user_id]+
    # * *Returns* :
    #   - current template array
    # * *Raises* :
    #   - +TypeError+ -> if the +groups+ param is not an +Array+
    def grouped(name, groups)
      raise TypeError, "Second parameter 'groups' must be an array" unless groups.is_a? Array
      @template_array << { name => groups }
    end
  end

  class GroupedNotLastError < Exception
  end
end
