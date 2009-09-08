function _template_errortest_lua()
local _out = {}; function out(s) table.insert(_out, tostring(s)); end table.insert(_out, "<h1>Heading</h1>\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "This is nice text\n"); 
table.insert(_out, "\n"); 
table.insert(_out, tostring(include(error_file or '_badinclude'))); 
table.insert(_out, "\n"); 
table.insert(_out, "and more text\n"); 
table.insert(_out, "\n"); 
if true then 
table.insert(_out, "  detail line\n"); 
end; 
return table.concat(_out)
end