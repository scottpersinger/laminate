module Laminate
  # Sample class for loading Laminate templates, loads them off the filesystem.
  class Loader
    # Default loader expects to load Laminate templates from the given directory by name (where names
    # can include relative paths).
    def initialize(basedir, extension = 'lam')
      @extension = extension
      @base = basedir || File.expand_path(".")
      raise "Invalid template directory '#{@base}'" unless File.directory?(@base)
    end
    
    # Load the Laminate template with the given name. Will look in <tt>basedir/name.lam</tt>.
    # Returns the template content as a string.
    def load_template(name)
      f = lam_path(name)
      if File.exist?(f)
        File.open(f).read
      else
        raise "Missing template file #{f}"
      end
    end
    
    # Returns true if the Laminate tempate needs to be compiled because either the erb template
    # doesn't exist or it is older the the .lam file.
    def needs_compile?(name)
      lam = lam_path(name)
      erb = lua_path(name)
      !File.exist?(erb) || (File.mtime(lam) > File.mtime(erb))
    end
    
    # Saves the compiled Ruby code back to the filesystem.
    def save_compiled(name, ruby_content)
      f = lua_path(name)
      File.open(f, "w") do |io|
        io.write(ruby_content)
      end
    end
    
    def load_compiled(name)
      File.read(lua_path(name))
    end

    def clear_cached_templates
      Dir.glob("#{@base}/*.lua").each {|f| File.delete(f)}
    end
    
    private
      def lam_path(name)
        fname = (name =~ /\.#{@extension}$/) ? name : "#{name}.#{@extension}"
        (fname =~ /^\// or fname =~  /^.:\//) ? fname : File.join(@base, fname)
      end
      
      def lua_path(name)
        lam_path(name).gsub(/\.#{@extension}$/,'') + '.lua'
      end
  end

  # Implements a simple in memory template loader which operates in memory. It always requires templates to be compiled.
  class InlineLoader < Loader
    def initialize(content)
      @content = content
      @ruby = {}
    end
    def load_template(name)
      @content
    end
    def needs_compile?(name)
      true
    end
    def save_compiled(name, content)
      @ruby[name] = content
    end
    def load_compiled(name)
      @ruby[name]
    end
  end
      
end
