module Laminate
  class Compiler
    # Compiles an HTML-Lua template in a Lua script.
    def compile(name, template_source)
      # lua is an array of source lines. Each element is one line of generated Lua code. These will be concatenated at the end to
      # return the full lua script.
      lua = []
      
      add_text = Proc.new do |str, newline|
        nl = newline ? "\\n" : ""
        str = escape_quotes(str)
        lua.last << "table.insert(_out, \"#{str}#{nl}\"); "
      end
      add_code = Proc.new do |code|
        if code !~ /^#/  # short circuit comments
          separator = (code =~ /(do|then|else|elseif|repeat)\s*$/) ? '' : ';'
          is_control = (code =~ /^\s*(if|while|repeat|until|for|else|elseif|break|end|function)\b/)
          is_assignment = (!is_control && code =~ /^\s*[\w\s,]+=[^=]/)
          if code =~ /^=(.*)/ || (!is_control && !is_assignment)
            code = $1 || code
            lua.last << "table.insert(_out, #{code})#{separator} "
          else
            lua.last << "#{code}#{separator} "
          end
        end
      end
      lua << "function #{lua_template_function(name)}()"
      # LUA: The _out var is an array (table). Each text fragment is appended to the array. Thus the array serves like the _erbout
      # string buffer in ERB. At the end, all the fragments are joined together to return the result.
      lua << 'local _out = {}; function out(s) table.insert(_out, tostring(s)); end; '
      
      # Split the template by lines. 
      template_source.each_line do |line|          
        line.chomp! if line =~ /\n$/
        # Match all the Lua scripts in the line
        matches = line.scan(/(.*?)\{\{(.*?)\}\}([^\{]*)/)
        if matches.empty?
          # No code, so just do line
          add_text.call(line, true)
          lua << ''
        else
          found_text = false
          matches.each do |tuple|
            left = tuple[0]
            code = tuple[1]
            right = tuple[2]
            #left.strip! if left.strip == '' # greedy strip code indentation
            found_text ||= (!blank?(left) || !blank?(right))
            add_text.call(left, false) #if left != ''  
            add_code.call(code)
            add_text.call(right, false) if right != ''
          end
          add_text.call('', true) if true #found_text # LUA: newline if any regular text on the line
          lua << ''
        end 
      end
      if lua.last == "\n" || lua.last == ''
        lua.pop
      end
      lua << "return table.concat(_out)"
      lua << "end"
      lua.join("\n")
    end

    def blank?(str)
      str.nil? || str.strip == ''
    end
    
    def lua_template_function(name)
      "_template_#{name}".gsub(/[ \.]/,'_')
    end
    
    def escape_quotes(str)
      str.gsub('\"', '\\\\\\"').gsub(/"/,'\"')
    end
    

  end # class Compiler
end