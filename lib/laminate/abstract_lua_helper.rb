module Laminate
  class AbstractLuaHelper
    def self.namespace(*args)
      @namespaces = args
      @post_processing = {}
    end
  
    def self.namespaces
      @namespaces || []
    end
    
    # Calling post_process allows you to specify a Lua function to be use to manipulate Ruby results before they are
    # returned the caller in Laminate.
    # Usage:
    #   post_process :afunction, :util_function2, :with => 'check_ruby'
    # 
    # So a list of function names (including namespace) and :with indicating the Lua function to invoke. This function
    # will be passed the result of the Ruby call, and its results will be returned to the Laminate caller.
    def self.post_process(*args)
      lua_func = nil
      args.each {|elt| (lua_func = elt[:with] and args.delete(elt)) if elt.is_a?(Hash)}
        
      args.each {|ruby_func| @post_processing[ruby_func.to_s] = lua_func}
    end

    def self.post_process_func(meth_name)
      @post_processing[meth_name.to_s]
    end    
    
    # Decends a tree of values and returns a hash/array serialized from the tree.
    # Scalar values are returned as is.
    # Array values are returned as an array with each element serialized.
    # Hash values are returned as a hash with keys converted to strings and elements serialized.
    #
    # For any other type, a serializer map is determined by searching in the serializers hash by the object's class.
    # If a map is found, then #serialize_by_map is called to serialize the object.
    def hash_serialize(value, options = {})
      serializers = options[:serializers] || {}
      case value
      when Array
        value.collect {|child| hash_serialize(child, :serializers => serializers)}
      when Hash
        result = {}
        value.each do |key, value|
          result[key.to_s] = hash_serialize(value, :serializers => serializers)
        end
        result
      when Time
        value.to_f
      else
        # Look for serializer map
        if map = serializers[value.class]
          serialize_by_map(value, map, serializers)
        else
          value
        end
      end
    end
    
    # Serializes the value according to the serializer map array.
    # Serializer maps are an array of fields to serialize from the object.
    # Each field may be one of:
    #   * symbol/string - That function is executed on the object and the result serialized
    #   * hash of name => string value. The string is eval'd against the object and the result serialized as 'name'.
    #   * hash of name => proc. The Proc is executed, passing in the object, and the result serialized as 'name'.
    #   * Array, another serializer map. This map will be used to serialize the target value.
    def serialize_by_map(value, map, serializers)
      if value.is_a?(Array)
        return (value.collect {|v| serialize_by_map(v, map, serializers)})
      end
      
      result = {}
      map.each do |key|
        begin
          if key.is_a?(String) || key.is_a?(Symbol)
            result[key.to_s] = hash_serialize(value.send(key.to_sym), :serializers => serializers)
          else
            k = key.keys.first
            helper = key[k]
            if helper.is_a?(Proc)
              # Invoke the proc, passing in the top object, serialize, set using name
              result[k.to_s] = hash_serialize(helper.call(value), :serializers => serializers)
            elsif helper.is_a?(Array)
              # Call name on the object to get raw value, then serialize with sub-map, and set using name
              child = value.send(k.to_sym)
              result[k.to_s] = serialize_by_map(child, helper, serializers)
            else
              # Eval string against the top object, serialize result, and set result using name
              result[k.to_s] = hash_serialize(eval("value.#{helper}"), :serializers => serializers)
            end
          end
        rescue Exception => err
          puts "Error serializing '#{key} in #{value}: #{err.message}"
          puts err.backtrace.join("\n")
        end
      end
      result
    end
  end
end

  