# Require this file to enable timeouts in Lua scripts by virtue of SIGALRM.
# You will need a patched lualib shared library that includes the lalarm library.

require 'laminate/rufus_lua_alarm'
Laminate::Template.enable_timeouts = true
