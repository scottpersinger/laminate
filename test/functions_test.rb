require 'helper'
require 'laminate'
require 'laminate/timeouts'

module TestFuncs
  def my_value
    42
  end
  
  def divider(v1, v2)
    v1  /  v2
  end
  
  def favorite_tv(a, b, c)
    a ||= "Daily Show"
    b ||= "Colbert"
    c ||= "South Park"
    "#{a}, #{b}, #{c}"
  end
  
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

  def test5(arg1, options)
    arg1 ||= 'val1'
    options ||= {}
    
    puts "Arg1: #{arg1}, options: #{options.inspect}"
  end
  
  def get_now
    Time.now
  end  
  
  def get_today
    Date.today
    Time.now
  end
end

class Mysecrets
  def initialize
    @secret = 42
  end
  
  def is_this_it(compare)
    compare == @secret ? "Yes!" : "No..."
  end
end

class NestedFunctionsHelper < Laminate::AbstractLuaHelper
      namespace 'vodspot', 'vodspot.collections'
  # The 'post_process' call can indicate another Lua function which will process Ruby results before they are returned to the template caller.
  # See the test below that defines the 'getdouble' Lua function.
  post_process :get42, :vodspot_get42, :with => 'getdouble'
  post_process :vodspot_colors, :with => 'annotate_table'
  post_process :search, :with => '_rb_post_process'
  
  def vodspot_videos
    "list of vodspot videos"
  end

  # Matches prefix, and method includes a '_'
  def vodspot_video_id
    99
  end
    
  # Matches prefix but doesn't have the separator - should bind to top level  
  def vodspottop_level
    "topper"
  end
  
  def toplevel
    "non-nested function"
  end
  
  def vodspot_collections_first
    "first vodspot collection"
  end
  
  def get42
    42
  end
  
  def vodspot_get42
    42
  end
  
  def vodspot_colors
    {:results => ['red','green','blue','orange'], :total_colors => 100}    
  end
  
  def search
    {'search_results' => ['result 1', 'result 2', 'result 3'], 'page' => 1, 'total' => 100}
  end
end

  
class FunctionsTest < Test::Unit::TestCase
  test "simple functions" do
puts "simple functions"
    template = "secret of the universe is {{my_value()}} and the same value is {{divider(84,2)}}\n\
    is the secret 20? {{is_this_it(20)}}\n\
    is the secret 5? {{is_this_it(5)}}\n\
    is the secret 42? {{is_this_it(42)}}\n"
    
    lam = Laminate::Template.new(:text => template)
    
    res = lam.render(:helpers => [TestFuncs, Mysecrets.new])
    assert res =~ /secret of the universe is 42/
    assert res =~ /same value is 42/
    assert res =~ /is the secret 42\? Yes/
  end
  
  test "auto conversion of Date and Time" do
    puts "auto conversion of date"
    template = "The current Time in seconds equals: {{ get_now() }} and today in seconds equals: {{ get_today() }}"
    lam = Laminate::Template.new(:text => template)
    
    now = Time.now
    res = lam.render(:helpers => [TestFuncs])
    
    assert res =~ /seconds equals: #{now.to_i}/  end
  
  test "debug_all" do
    puts "debug-all"
    lam = Laminate::Template.new(:text => "Debug info:\n{{debug_all()}}")
    res = lam.render(:locals => {:name => 'Ron Burgundy', :colors => ['gold', 'purple']}, :helpers => [TestFuncs, Mysecrets.new])
    
    assert res =~ /name.*Ron Burgundy/
    assert res =~ /colors.*purple/
    assert res =~ /TestFuncs.*divider/
    assert res =~ /Mysecrets.*is_this_it/
  end
  
  test "nested functions" do
    puts "nested functions"
    lam = Laminate::Template.new(:text => <<-ENDCODE
    top level: {{toplevel()}}
   first level: {{vodspot.videos()}}
    second level: {{vodspot.collections.first()}}
    with underscore: {{vodspot.video_id()}}
    non-match: {{vodspottop_level()}}
    ENDCODE
    )
    res = lam.render(:helpers => [NestedFunctionsHelper.new])
    
    assert res =~ /top level: non-nested/
    assert res =~ /first level: list of vodspot videos/
    assert res =~ /second level: first vodspot collection/
    assert res =~ /with underscore: 99/
    assert res =~ /non-match: topper/
  end
  
  test "debug function" do
    puts "debug function"
    lam = Laminate::Template.new(:text => "your profile:\n{{debug(profile)}}\ncolor: {{ debug(color) }}")
    
    res = lam.render(:locals => {:color => 'blue', :profile => {:name => 'Chazz Rheinhold', :age => 39}})
    assert res =~ /name.*Chaz/
    assert res =~ /age.*39/
    assert res =~ /color: blue/
  end
  
  test "default values" do
    puts "default values"
    lam = Laminate::Template.new(<<-ENDCODE
    1: {{favorite_tv()}}
    2: {{favorite_tv('Dynasty')}}
    3: {{favorite_tv('Dynasty','Dallas')}}
    4: {{favorite_tv('Dynasty', 'Dallas', 'Knots Landing')}}
    ENDCODE
    )

    res = lam.render(:helpers => [TestFuncs])

    assert res =~ /2: Dynasty,/
    assert res =~ /3: Dynasty, Dallas,/
    assert res =~ /4: Dynasty, Dallas, Knots Landing/
   end
   
   test "out function" do
     puts "out function"
     lam = Laminate::Template.new("{{ for i,k in ipairs({'red','white'}) do out(k .. ' '); end }}and blue")
     
     res = lam.render
     puts res
     assert res =~ /red white and blue/   end
   
   test "argument values" do
     puts "argument values"
     lam = Laminate::Template.new(<<-ENDCODE
     {{mybool = true}} {{mys = 'foobar'}} {{mynum=3.14}} {{ mytable = {a='ay',b='bee'} }} {{ myary = {'one','two','three'} }}
     {{ mynested = {a = 'aye', b = {one = '1', two = '2'} } }}
     {{ check_types(mybool,mys,mynum,mytable,myary,mynested) }}
     ENDCODE
     )
     
     puts "arg values 2"
     res = lam.render(:helpers => [TestFuncs])
puts "arg values 3"
     assert res =~ /types OK/   end
   
   test "ending options hash" do
     puts "ending options"
     lam = Laminate::Template.new(<<-ENDCODE
       {{ test5() }}
       {{ test5('next one') }}
       {{ f = {a='aye',b='bee'} }}
       {{ test5('hello', f) }}
     ENDCODE
     ) 
     puts lam.render(:helpers => [TestFuncs])   end

   test "template inclusion" do
     puts "template inclusion"
     lam = Laminate::Template.new(:file => "fixtures/includetest.lam")
   
     res = lam.render(:locals => {:word => "hello", :name => "Scott <b>The Ram!</b> Persinger"})

     assert res =~ /hello/, "Hello appears in output"
     assert res =~ /<h1>/, "Include HTML is not escaped"
     
   end

   # Look at NestedFunctionsHelper above to see how to indicate that a Lua function should process Ruby results
   # before returning them to the Laminate caller.
   test "Results post processing" do
     puts "result post"
     lua =<<-ENDLUA
     {{ function getdouble(i) return i*2; end }}
     {{ get42() }} = 84
     Nested {{ vodspot.get42() }} --> 84
     ENDLUA
     
     lam = Laminate::Template.new(:text => lua)
     puts "result post 2"
     res = lam.render(:helpers => [NestedFunctionsHelper.new])
     assert res =~ /84 = 84/
     assert res =~ /Nested 84 --> 84/
     
     # Test table annotation (attaching attributes to a Lua array). This is especially useful for annotating an
     # array with a "total" attribute. This is easy in Lua. Laminate includes a built-in "_rb_post_process" function
     # which can do this for you. Just have your Ruby function return any hash containing one array and 1 or more
     # scalars.
     lua =<<-ENDLUA
     {{ function annotate_table(tuple) res = tuple.results; res.total_colors = tuple.total_colors; return res; end }}
     {{ colors = vodspot.colors() }} 
     Got {{ #colors }} out of {{ colors.total_colors }} total
     {{ search_results = search() }}
     Search returned {{ for i,v in ipairs(search_results) do out(v .. ','); end }} from page {{ search_results.page }} of {{ search_results.total }}
     ENDLUA
      
     lam = Laminate::Template.new(:text => lua)
     
puts "result post 3"
     res = lam.render(:helpers => [NestedFunctionsHelper.new])
     assert res =~ /Got 4 out of 100 total/
     assert res =~ /Search returned result 1,result 2,result 3, from page 1 of 100/
   end   
end

