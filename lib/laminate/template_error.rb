require 'cgi'

module Laminate
  class TemplateError < RuntimeError
    def initialize(err, template_name, template_src, logger = nil)
      if err.is_a?(Array)
        err = err.first
      end
      @err = err
      if @err.is_a?(String)
        @err = Exception.new(@err)
      end
      if logger
        logger.error(@err)
        logger.error(@err.backtrace.join("\n")) if @err.backtrace
      end
      @name = template_name
      @source = (template_src || '').split("\n")
      @lua_line_offset = -1
    end
    
    def lua_line_offset=(val)
      @lua_line_offset = val
      @line = nil
    end
    
    def line_number
      @line ||= begin
        if @err.message =~ /line (\d+)/ || @err.message =~ /\(erb\):(\d+)/ || (@err.backtrace && @err.backtrace.join("\n") =~ /\(erb\):(\d+)/)
	        $1.to_i
	      elsif @err.message =~ /:(\d+):/
	        $1.to_i + @lua_line_offset
	      else
	        -1
	      end
      end
    end
    
    def line_label
      line_number >= 0 ? line_number.to_s : '?'
    end
    
    def col_number
      if @err.message =~ /column (\d+)/
        $1.to_i
      else
        1
      end
    end
    
    def extract
      line = line_number-1
      if line >= 0
	      if line < @source.size
	        if line > 0
	          [@source[line-1], highlight(@source[line]), @source[line+1].to_s].join("\n")
	        else
	          [highlight(@source[line]), @source[line+1].to_s].join("\n")
	        end
	      end
      else
        ''
      end
    end

    def highlight(line)
      res = line
      res << "\n" 
      (col_number-1).times {res << '.'}
      res << "^\n"
      res
    end
          
    def message
      if @err.message =~ /expecting kEND/
        "expecting {{end}} tag"
      else
        m = @err.message
        # Strip Rufus::Lua error anotation to template error is easier to read
        if m =~ /:\d+:(.*)\([123]\)/
          m = $1
        else
          if @err.backtrace && @err.backtrace.first
            m << " [#{@err.backtrace.first}]"
          end
        end
        m
      end
    end
    
    def sanitize(str)
      (str || '').gsub('<', '&lt;').gsub('>', '&gt;')
    end
    
    def to_s
      "Template '#{@name}' returned error at line #{line_label}: #{message}\n\nExtracted source\n#{extract}"
    end
    
    def to_html
      "<style>code {background:#DDD}</style><br />" +
      "Template '#{@name}' returned error at line #{line_label}: #{sanitize(message)}\n\nExtracted source\n<pre><code>#{sanitize(extract)}</code></pre>".gsub("\n","<br />")
    end
  end
end

  