require 'time'

module DeepStruct
  class DeepWrapper
    def initialize(value)
      @value = value
    end
    
    def raw_value
      @value
    end
    
    def [](index)
      return DeepRecord.wrap(@value[index])
    end
    
    def []=(index, value)
      @value[index] = value
    end
    
    def inspect
      "#<#{self.class} #{@value.inspect}>"
    end
  end
  
  class HashWrapper < DeepWrapper
    def method_missing(method, *args, &block)
      method = method.id2name
      arg_count = args.length
      if method.chomp!('=')
        if arg_count != 1
          raise ArgumentError, "wrong number of arguments (#{arg_count} for 1)", caller(1)
        end
        if @value[method]
          @value[method] = args[0] 
        else
          @value[method.to_sym] = args[0]
        end
      elsif arg_count == 0
        DeepRecord.wrap(@value[method] || @value[method.to_sym])
      else
        raise NoMethodError, "undefined method `#{method}' for #{self}", caller(1)
      end
    end
  end
  
  class ArrayWrapper < DeepWrapper
    include Enumerable

    def each
      block_given? or return enum_for(__method__)
      @value.each { |o| yield(DeepRecord.wrap(o)) }
      self
    end

    def size
      @value.size
    end
    alias :length :size
  end
  
  # Attempt to convert the string to its natural ruby type
  def self.parse(string)
    return string.to_i if string.to_i.to_s == string
    return string.to_f if string =~ /^\-?\d+\.\d+(?:e\-?\d+)$/
    
    # try time
    begin
      return Time.parse(string)
    rescue ArgumentError
    end        
    
    # Try json
    begin
      return DeepRecord.wrap(JSON.parse(string)) if defined?(JSON)
    rescue JSON::ParserError
    end
      
    return string
  end
  
  def self.wrap(value)
    case value
    when String
      self.parse(value)
    when Hash
      return HashWrapper.new(value)
    when Array
      return ArrayWrapper.new(value)
    else
      return value
    end
  end
end