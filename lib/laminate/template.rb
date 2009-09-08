begin
  require 'rufus/lua'
rescue Exception => err
  puts "Error, Laminate failed to load because Rufus/Lua failed to load: #{err.message}"
end

require 'logger'

module Laminate
  STANDARD_LUA_LIBS = [:base, :string, :math, :table]

  class LuaView
  end

  # Create a Template so that you can render it. A Template is created by either passing in the text of the template,
  # or by passing in a #Loader instance which knows how to load templates.
  #
  # Examples:
  #    template = Laminate::Template.new(:text => "<h1>Hello {{user.name}}</h1>")
  #
  #    template = Laminate::Template.new(:file => "my/template/path/template1.lam") 
  # Will load templates from the indicated directory, named by their file names. Use :clear => true to delete compiled templates on the file system.
  #
  #    template = Laminate::Template.new(:name => "template1", :loader => my_loader_class)
  # Loads 'template1' by using the passed #Loader instance.
  #
  # Note that the template is not compiled until you call #render. 
  #
  # == Included templates
  # 
  # A template may call the 'include' function to include another template. This mechanism only works if
  # you have created the Template using either :loader or :file. The included template has the same access
  # to the current state as the parent template.
  class Template
    
    @@enable_timeouts = false
    # Enable or disable Lua timeouts. You shouldn't call this function directly, but rather use: require 'laminate/timeouts'. That
    # helper includes all the required timeout components and enables this setting.
    def self.enable_timeouts=(val)
      @@enable_timeouts = val
    end
    
    def self.enable_timeouts
      @@enable_timeouts
    end    
    
    def initialize(options = {})
      @errors = []
      @logger = options[:logger]
      @compiler = Compiler.new
            
      if options[:file]
        @name = options[:file]
        view_dir = File.dirname(@name)
        @name = File.basename(@name)
        @loader = Loader.new(File.expand_path(view_dir), 'lam')
        if options[:clear]
          @loader.clear_cached_templates
        end
      elsif options[:name] && options[:loader]
        @name = options[:name]
        @loader = options[:loader]
      elsif options[:text]
        @loader = InlineLoader.new(options[:text])
        @name = "inline"
      elsif options.is_a?(String)
        @loader = InlineLoader.new(options)
        @name = "inline"
      else
        @name = "inline"
        @loader = InlineLoader.new("No template supplied")
      end
      
      # Some recordings for debug purposes
      @helper_methods = []
      @local_data = []
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end
           
    def clear_cached_templates
      if @loader.respond_to?(:clear_cached_templates)
        @loader.clear_cached_templates
      end
    end
    
    def lua_script
      @loader
    end
    
    def has_errors?
      @errors.size > 0
    end
    
    def get_errors
      @errors
    end
  
    def compile(name = nil)
      name ||= @name
      prepare_template(name)
      begin
        state = Rufus::Lua::State.new(STANDARD_LUA_LIBS)
        sandbox_lua(state)
        state.eval(@loader.load_compiled(name))
        return true
      rescue Rufus::Lua::LuaError => err
        @errors << Laminate::TemplateError.new(err, name, @loader.load_template(name))
        return false
      end
    end
       
    def load_template(name)
      @loader.load_template(name)
    end
       
    def template_source(name)
      prepare_template(name)
      @loader.load_compiled(name)
    end
    
    def test_lua_compiler(str)
      @compiler.compile('test', str)
    end

    def render!(options = {})
      render(options.merge(:raise_errors => true))
    end
    
    # Renders the template assigned at construction. Options include:
    #   :locals -> A hash of variables to make available to the template (simply types, Hashes, and Arrays only. Nesting OK)
    #   :helpers -> An array of Modules or instances to make available as functions to the template.
    #   :raise_errors -> (true|false) If true, then errors raise an exception. Otherwise an error message is printed as the template result.
    #   :wrap_exceptions => (*true|false) If true, then Ruby exceptions are re-raised in Lua. This incurs a small performance penalty.
    #   :timeout -> Max run time in seconds for the template. Default is 15 secs.
    #
    # Returns the text of the rendered template.
    def render(options = {})
      #debugger
      #puts ">> LAMINATE RENDER START. Disabling gc."
      #GC.disable
      # Compile template if needed
      name = @name.dup
      prepare_template(name)
      lua = @loader.load_compiled(name).dup

      timeout = (options[:timeout] || 15).to_i
        
      @errors = []
      @wrap_exceptions = !options[:wrap_exceptions].nil? ? options[:wrap_exceptions] : true
      
      state = Rufus::Lua::State.new(STANDARD_LUA_LIBS)
      sandbox_lua(state)
      view = LuaView.new
      Rufus::Lua::State.debug = true if ENV['LUA_DEBUG']
      
      begin
        # Template eval just defines the template function
        state.eval(lua)

        setup_builtin_funcs(state)

        if options[:locals]
          load_locals(options[:locals], state) and nil
        end
        if options[:helpers]
          load_helpers(options[:helpers], state, view) and nil
        end
      
        if @@enable_timeouts
          state.eval("alarm(#{timeout}, function() error('template timeout'); end)")
          state.eval("alarm = function(arg, arg) end")  
        end
        state.eval("return #{@compiler.lua_template_function(name)}()")
      rescue Rufus::Lua::LuaError => err
        i = 1
        log_code = '1 ' + lua.gsub("\n") { |m| "\n#{i+=1} " }
        logger.error "LUA ERROR: #{err}\nfrom template:\n#{log_code}"
        if err.message =~ /included template: '(.*?)'/
          # Lua-include function will generate an error message with the included template name, so
          # make sure to peg exception to that template
          name = $1
          wrapper = TemplateError.new(err, name, @loader.load_template(name), logger)
          wrapper.lua_line_offset = 0
          logger.error "Created Template Error wrapper:\n#{wrapper.to_html}"
        else
          wrapper = TemplateError.new(err, @name, @loader.load_template(name), logger)
        end
        if options[:raise_errors]
          raise wrapper
        else
          @errors << wrapper
          return wrapper.to_html
        end
      ensure
        # currently we aren't keeping around the Lua state between renders
        
        # Clear the alarm signal handler so it doesn't call back into a deleted Lua state
        if @@enable_timeouts
          Rufus::Lua::Lib._clear_alarm
        end
        
        state.close if state
        #puts "<< END LAMINATE RENDER. Enabling gc."
        #GC.enable
      end
      
    end

    def sandbox_lua(state)
      # Should include string.find ...
      [:loadfile, :collectgarbage, :_G, :getfenv, :getmetatable, :setfenv, :setmetatable, 'string.rep'].each do |badfunc|
        state.eval("#{badfunc} = nil")
      end
      state.eval("function string.rep(count) return 'rep not supported'; end")
      if @@enable_timeouts
        state.init_lua_alarm
      end
    end
    
    def load_helpers(helpers, state, view)
      helpers.each do |helper|
        if helper.is_a?(Module)
          LuaView.send(:include, helper)
          bind_lua_funcs(view, helper.public_instance_methods(false), helper, state, view)
          nil
        else
          bind_lua_funcs(helper, helper.class.public_instance_methods(false), helper.class, state, view)
          nil
        end
      end
      return
    end
      
#  private
 
    # Compiles the indicated template if needed
    def prepare_template(name)
      if @loader.needs_compile?(name)
        lua = @compiler.compile(name, @loader.load_template(name))
        @loader.save_compiled(name, lua)
      end
    end

    def load_locals(locals_hash, state)
      stringify_keys!(locals_hash)
      state.function '_getlocal' do |name|
        locals_hash[name]
      end
      locals_hash.keys.each {|key| state.eval("#{key} = _getlocal('#{key}')")}
      # Record locals for debug_info function
      @local_data = locals_hash.keys.collect {|k| k.to_s}
      return
    end
    
    def bind_lua_funcs(target, methods, source_module, state, view)
      methods.each do |meth|
        argument_count = target.method(meth).arity
        if argument_count < 0
          raise "Ruby-style optional arguments for function '#{meth}' are not supported. Please use Javascript-style defaults instead."
        end
        
        # Save the ruby name so we can invoke it with 'send' in the Lua callback block
        ruby_method_name = meth.to_s.dup
        
        # Handle namespacing. This allows helpers to place functions under table containers.
        # So the helper:
        #   class Helper
        #     def self.namespaces; [:my]; end
        #
        #     def my_videos
        #       [...data...]
        #     end
        #   end
        #
        # will implement a Lua function available as "my.videos" which will call the "my_videos" function. Methods
        # are matched to namespaces by the prefix.
        namespaces = target.class.respond_to?(:namespaces) ? target.class.namespaces : []
        lua_post_func = target.class.respond_to?(:post_process_func) ? target.class.post_process_func(meth) : nil
        
        # Find namespaces matching the method, then return the longest one
        ns = namespaces.select {|ns| meth.gsub('_', '.').index("#{ns}.") == 0}.sort {|a, b| b.to_s.length <=> a.to_s.length}.first
        if ns
          meth = "#{ns}.#{ruby_method_name[ns.to_s.length+1..-1]}"
          ensure_namespace_exists(ns.to_s, state)
        end
        
        # Record for debugging purposes
        @helper_methods << "#{source_module}: #{meth}"
        setup_func_binding(target, meth.to_s, ruby_method_name, argument_count, state, view, lua_post_func)
      end
      
      return
    end
    
    # Binds the indicated ruby method into the Lua runtime. To support optional arguments,
    # a Lua "wrapper" function is created. So the call chain looks like:
    #
    #   <name>(arg1, arg2, ...)
    #     invokes <name>__
    #
    #   <name>__ => bound to Ruby block
    #
    # This allows us to use Lua's ability to ignore omitted arguments. Since our Ruby block must always
    # be passed the right number of args, our wrapper function has the effect of defining those missing
    # args as nil.
    
    def setup_func_binding(target, lua_name, ruby_name, argument_count, state, view, lua_post_func)
      ruby_bound_name = "#{lua_name}_r_"
      
      if !@wrap_exceptions
        case argument_count
        when 0
          state.function(lua_name) do
            target.send(ruby_name)
          end
        when 1
          state.function(lua_name) do |arg1|
            target.send(ruby_name, arg1)
          end
        when 2
          state.function(lua_name) do |arg1, arg2|
            target.send(ruby_name, arg1, arg2)
          end
        when 3
          state.function(lua_name) do |arg1, arg2, arg3|
            target.send(ruby_name, arg1, arg2, arg3)
          end
        when 4
          state.function(lua_name) do |arg1, arg2, arg3, arg4|
            target.send(ruby_name, arg1, arg2, arg3, arg4)
          end
        when 5
          state.function(lua_name) do |arg1, arg2, arg3, arg4, arg5|
            target.send(ruby_name, arg1, arg2, arg3, arg4, arg5)
          end
        when 6
          state.function(lua_name) do |arg1, arg2, arg3, arg4, arg5, arg6|
            target.send(ruby_name, arg1, arg2, arg3, arg4, arg5, arg6)
          end
        when 7
          state.function(lua_name) do |arg1, arg2, arg3, arg4, arg5, arg6, arg7|
            target.send(ruby_name, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
          end
        else
          raise "Ack! Too many arguments to helper function #{ruby_name}: try using an options hash"          
        end
        
      else
        case argument_count
        when 0
          state.function(ruby_bound_name) do
            begin
              target.send(ruby_name)
            rescue Exception => err
              logger.error(err.message)
              logger.error(err.backtrace.join("\n"))
              state.eval("_rb_error = [[#{err.message}]]")
              nil
            end
          end
          state.eval("function #{lua_name}() _rb_error = nil; return #{lua_post_func}(_rb_assert(#{ruby_bound_name}(), _rb_error)); end")
        when 1
          state.function(ruby_bound_name) do |arg1|
            begin
              target.send(ruby_name, arg1)
            rescue Exception => err
              logger.error(err.message)
              logger.error(err.backtrace.join("\n"))
              state.eval("_rb_error = [[#{err.message}]]")
              nil
            end
          end
          state.eval("function #{lua_name}(arg1) _rb_error = nil; return #{lua_post_func}(_rb_assert(#{ruby_bound_name}(arg1), _rb_error)); end")
        when 2
          state.function(ruby_bound_name) do |arg1,arg2|
            begin
              target.send(ruby_name, arg1, arg2)
            rescue Exception => err
              logger.error(err.message)
              logger.error(err.backtrace.join("\n"))
              state.eval("_rb_error = [[#{err.message}]]")
              nil
            end
          end
          state.eval("function #{lua_name}(arg1,arg2) _rb_error = nil; return #{lua_post_func}(_rb_assert(#{ruby_bound_name}(arg1,arg2), _rb_error)); end")
        when 3
          state.function(ruby_bound_name) do |arg1,arg2,arg3|
            begin
              target.send(ruby_name, arg1, arg2, arg3)
            rescue Exception => err
              logger.error(err.message)
              logger.error(err.backtrace.join("\n"))
              state.eval("_rb_error = [[#{err.message}]]")
              nil
            end
          end
          state.eval("function #{lua_name}(arg1,arg2,arg3) _rb_error = nil; return #{lua_post_func}(_rb_assert(#{ruby_bound_name}(arg1,arg2,arg3), _rb_error)); end")
        when 4
          state.function(ruby_bound_name) do |arg1,arg2,arg3,arg4|
            begin
              target.send(ruby_name, arg1, arg2, arg3,arg4)
            rescue Exception => err
              logger.error(err.message)
              logger.error(err.backtrace.join("\n"))
              state.eval("_rb_error = [[#{err.message}]]")
              nil
            end
          end
          state.eval("function #{lua_name}(arg1,arg2,arg3,arg4) _rb_error = nil; return #{lua_post_func}(_rb_assert(#{ruby_bound_name}(arg1,arg2,arg3,arg4), _rb_error)); end")
        when 5
          state.function(ruby_bound_name) do |arg1,arg2,arg3,arg4,arg5|
            begin
              target.send(ruby_name, arg1, arg2, arg3,arg4,arg5)
            rescue Exception => err
              logger.error(err.message)
              logger.error(err.backtrace.join("\n"))
              state.eval("_rb_error = [[#{err.message}]]")
              nil
            end
          end
          state.eval("function #{lua_name}(arg1,arg2,arg3,arg4,arg5) _rb_error = nil; return #{lua_post_func}(_rb_assert(#{ruby_bound_name}(arg1,arg2,arg3,arg4,arg5), _rb_error)); end")
        when 6
          state.function(ruby_bound_name) do |arg1,arg2,arg3,arg4,arg5,arg6|
            begin
              target.send(ruby_name, arg1, arg2, arg3,arg4,arg5,arg6)
            rescue Exception => err
              logger.error(err.message)
              logger.error(err.backtrace.join("\n"))
              state.eval("_rb_error = [[#{err.message}]]")
              nil
            end
          end
          state.eval("function #{lua_name}(arg1,arg2,arg3,arg4,arg5,arg6) _rb_error = nil; return #{lua_post_func}(_rb_assert(#{ruby_bound_name}(arg1,arg2,arg3,arg4,arg5,arg6), _rb_error)); end")
        when 7
          state.function(ruby_bound_name) do |arg1,arg2,arg3,arg4,arg5,arg6,arg7|
            begin
              target.send(ruby_name, arg1, arg2, arg3,arg4,arg5,arg6,arg7)
            rescue Exception => err
              logger.error(err.message)
              logger.error(err.backtrace.join("\n"))
              state.eval("_rb_error = [[#{err.message}]]")
              nil
            end
          end
          state.eval("function #{lua_name}(arg1,arg2,arg3,arg4,arg5,arg6,arg7) _rb_error = nil; return #{lua_post_func}(_rb_assert(#{ruby_bound_name}(arg1,arg2,arg3,arg4,arg5,arg6,arg7), _rb_error)); end")
        else
          raise "Ack! Too many arguments to helper function #{ruby_name}: try using an options hash"          
        end
      end
      
    end
    
    def setup_builtin_funcs(state)
      state.function 'debug_all' do
        "<pre>Functions:\n  " +
        @helper_methods.join("\n  ") +
        "\nData:\n" +
        @local_data.collect do |local| 
          val = state[local]
          val = val.is_a?(String) ? val : (val.respond_to?(:to_h) ? val.to_h.inspect : val.to_s)
          "  #{local} = #{val}"
        end.join("\n") + "</pre>"
      end
      
      state.eval(<<-ENDLUA
      function _rb_assert(result, err_message)
        if result == nil and err_message ~= nil then
          error(err_message, 3)
        end
        return result
      end
    
      function _rb_post_process(ruby_result)
        if type(ruby_result) == 'table' then
          local result
          for k,v in pairs(ruby_result) do
            if type(v) == 'table' then
              result = v
            end          end
          for k,v in pairs(ruby_result) do
            if type(v) ~= 'table' then
              result[k] = v
            end
          end
          return result
        else
          return ruby_result
        end    
      end

      function debug (t, indent, done)
        if t == nil then
          return '<nil>'
        end
        if (type(t) == 'string' or type(t) == nil) then
          return tostring(t)
        end
        done = done or {}
        indent = indent or ''
        result = ''
        indentchars = '                                                                                                        '
        local nextIndent -- Storage for next indentation value
        for key, value in pairs (t) do
          if type (value) == "table" and not done [value] then
            nextIndent = nextIndent or
                (indent .. indentchars:sub(1, string.len(tostring (key))+2))
                -- Shortcut conditional allocation
            done [value] = true
            result = result .. (indent .. "[" .. tostring (key) .. "] => Table {\\n");
            result = result .. (nextIndent .. "{\\n");
            result = result .. debug (value, nextIndent .. indentchars:sub(1, 2), done) .. "\\n"
            result = result .. (nextIndent .. "}\\n");
          else
            result = result .. (indent .. "[" .. tostring (key) .. "] => " .. tostring (value).."\\n")
          end
        end
        return result
      end
      
      function string.escape(val)
        if val == nil then
          return ''
        end
        val = tostring(val)
        result = val:gsub('&', '&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"', '&quot;')
        return result
      end

      function slice(array, start, length)
        return {unpack(array, start, start+length-1)}
      end
      
      function string.trim(str)
          return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
      end

      function string.split(str, sep)
          local pos, t = 1, {}
          if #sep == 0 or #str == 0 then return end
          for s, e in function() return string.find(str, sep, pos) end do
              table.insert(t, string.trim(string.sub(str, pos, s-1)))
              pos = e+1
          end
          table.insert(t, string.trim(string.sub(str, pos)))
          return t
      end
      ENDLUA
      )
      # Included template functions. The trick is that we don't return to Ruby and eval the included template, because the
      # Lua binding doesn't like re-entering eval. So instead we bind a function '_load_template' which returns the template
      # code, and then we eval it inside Lua itself using 'loadstring'. Thus the template 'include' function is actually
      # a native Lua function.
      state.function '_load_template' do |name|
        prepare_template(name)
        load_template_innerds(name)
      end
      
      # Build the 'include' function in Lua/
      state.eval(<<-ENDBLOCK
      function include(name, ignore_errors)
        local f, err = loadstring(_load_template(name))
        if not f then
          print("********* LUA: " .. err)
          if ignore_errors then
            return "<!-- error from included template '" .. name .. "': " .. err .. " -->"
          end
          error("Error from included template: '" .. name .. "': " .. err, 0)
        else
          status, result = pcall(f)
          if status then
            return result
          else
            if ignore_errors then
              return "<!-- error from included template '" .. name .. "': " .. result .. " -->"
            end
            error("Error from included template: '" .. name .. "': " .. result, 0)
          end
        end
      end
      ENDBLOCK
      )
    end
    
    # Ensures that the Lua context contains nested tables matching the indicated namespace
    def ensure_namespace_exists(namespace, state)
      parts = namespace.split('.')
      0.upto(parts.size-1) do |idx|
        table = parts[0..idx].join('.')
        unless state[table]
          state.eval("#{table} = {}")
        end
      end
    end
    
    # Returns just the body of the template function
    def load_template_innerds(name)
      body = @loader.load_compiled(name)
      body.split("\n")[1..-2].join("\n")
    end
    
    # Recursively converts symbol keys to string keys in a hash
    def stringify_keys!(hash)
      if hash.is_a?(Hash)
        hash.keys.each do |key|
          hash[key.to_s] = stringify_keys!(hash.delete(key))
        end
        hash
      elsif hash.is_a?(Array)
        hash.collect {|elt| stringify_keys!(elt)}
      else
        hash
      end
    end
    
  end #class Template
end
