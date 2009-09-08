function _template_sample_lua()
local _out = {}; function out(s) table.insert(_out, tostring(s)); end table.insert(_out, "<html>\n"); 
table.insert(_out, "  <body>\n"); 
table.insert(_out, "    <h1>Account: "); table.insert(_out, tostring(user.name)); table.insert(_out, "</h1>"); table.insert(_out, "\n"); 
table.insert(_out, "    <b>Salary: "); table.insert(_out, tostring(user.salary)); table.insert(_out, "</b>"); table.insert(_out, "\n"); 
table.insert(_out, "  </body>\n"); 
table.insert(_out, "</html>\n"); 
return table.concat(_out)
end