function _template_errortest_lam()
local _out = {}; function out(s) table.insert(_out, tostring(s)); end; table.insert(_out, "<h1>Heading</h1>\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "This is nice text\n"); 
table.insert(_out, "\n"); 
table.insert(_out, ""); table.insert(_out, include('_badinclude')); table.insert(_out, "\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "and more text\n"); 
table.insert(_out, "\n"); 
table.insert(_out, ""); table.insert(_out, loop(badvar)); table.insert(_out, "\n"); 
table.insert(_out, "  detail line\n"); 
table.insert(_out, ""); end; table.insert(_out, "\n"); 
return table.concat(_out)
end