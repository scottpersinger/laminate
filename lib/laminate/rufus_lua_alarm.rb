# Bind additional C funtions provided by the lalarm library into Rufus::Lua. These functions must have been
# linked into the lualib share library.

Rufus::Lua::Lib.class_eval do
  attach_function :luaopen_alarm, [ :pointer], :void
  attach_function :_clear_alarm, [], :void
end

Rufus::Lua::State.class_eval do
  def init_lua_alarm
    Rufus::Lua::Lib.luaopen_alarm(@pointer)
  end
end
