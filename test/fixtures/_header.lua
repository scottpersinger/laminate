function _template__header()
local _out = {}; function out(s) table.insert(_out, tostring(s)); end; table.insert(_out, "<h1>Hello "); table.insert(_out, name); table.insert(_out, "</h1>"); table.insert(_out, "\n"); 
return table.concat(_out)
end