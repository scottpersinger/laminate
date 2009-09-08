function _template__badinclude2()
local _out = {}; function out(s) table.insert(_out, tostring(s)); end table.insert(_out, "<p>This included file contains a runtime error</p>\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "\n"); 
myvar = func_not_exist(); 
table.insert(_out, "\n"); 
table.insert(_out, "<strong>bad footer</strong>\n"); 
return table.concat(_out)
end