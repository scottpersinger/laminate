# Define to_lua functions for Time and Date classes. These just pass the 
# number of seconds for the time into Lua as a float. These conversions are not
# defined by Rufus::Lua itself because they are application dependent.

Time.class_eval do
  def to_lua
    self.to_f
  end
end

#Date.class_eval do
#  def to_lua
#    self.to_f
#  end
#end
