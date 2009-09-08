function _template_includetest_lam()
local _out = {}; function out(s) table.insert(_out, tostring(s)); end; table.insert(_out, "<!-- Tests the Laminate 'include' function for including another template -->\n"); 
table.insert(_out, ""); table.insert(_out, include('_header')); table.insert(_out, "\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "The word for today is:\n"); 
table.insert(_out, "<p>"); table.insert(_out, word); table.insert(_out, "</p>"); table.insert(_out, "\n"); 
table.insert(_out, "\n"); 
table.insert(_out, ""); table.insert(_out, include('_footer')); table.insert(_out, "\n"); 
table.insert(_out, "\n"); 
table.insert(_out, "\n"); 
return table.concat(_out)
end