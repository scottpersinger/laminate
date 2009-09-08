function _template__badinclude()
local _out = {}; function out(s) table.insert(_out, tostring(s)); end table.insert(_out, "<p>This file is included</p>\n"); 
table.insert(_out, "\n"); 
for(var i =0; i < 10; i++); 
table.insert(_out, "loop: "); table.insert(_out, tostring(i)); table.insert(_out, "\n"); 
end; 
table.insert(_out, "\n"); 
table.insert(_out, "<strong>footer</strong>\n"); 
return table.concat(_out)
end