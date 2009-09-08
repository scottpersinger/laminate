require 'rubygems'
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../rufus-lua/lib')))
puts $:.inspect
require 'rufus-lua'

state = Rufus::Lua::State.new([:base, :string, :math, :table])

def check_types(abool, astring, anumber, ahash, anarray, nested_hash, nested2)
  puts "Abool: #{abool}"
  puts "Astring: #{astring}"
  puts "Anumber: #{anumber}"
  puts "Ahash: #{ahash.inspect}"
  puts "Anarray: #{anarray.inspect}"
  puts "Nested hash: #{nested_hash.inspect}"
  puts "Nested array: #{nested2.inspect}"
  
  if abool.is_a?(TrueClass) && astring.is_a?(String) && anumber.is_a?(Float) && ahash.is_a?(Hash) && anarray.is_a?(Array)
    "types OK"
  else
    "types are bad"
  end
end

state.function "check_types" do |arg1, arg2, arg3, arg4, arg5, arg6, arg7|
  check_types(arg1, arg2, arg3, arg4, arg5, arg6, arg7)
end

lua =<<ENDLUA
mybool = true
mys = 'foobar'
mynum=3.14
mytable = {a='ay',b='bee'}
myary = {'one','two','three'}
mynested = {a = 'aye', b = {one = '1', two = '2'} }
check_types(mybool,mys,mynum,mytable,myary,mynested)
ENDLUA

state.eval(lua)
