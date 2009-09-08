function _template__footer()
local _out = {}; function out(s) table.insert(_out, tostring(s)); end; table.insert(_out, "The footer!\n"); 
return table.concat(_out)
end