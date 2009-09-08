require 'helper'
require 'laminate'
require 'ruby-debug'

USE_MY_CODE = true

module RubyHelper
  def user
    "Tugg Speedman"
  end
  
  def profile
    {'name' => 'Jeff Portnoy', 'age' => 32, 'movies' => ['The Fatties','Piece \'o Shit 2']}
  end
end

class ComplexHelper < Laminate::AbstractLuaHelper
  namespace 'vodspot'
  
  def vodspot_simpleval
    "secret"
  end
  
end

class Myview
end

class StressTest 
  @@tests = []
  
  def self.test(name, &block)
    @@tests << [name, block]  
  end
  
  def self.notest(name, &block)
  end
  
  def run
    #GC.disable
    loops = ARGV[0] ? ARGV[0].to_i :  1
    loops.times do |idx|
      @@tests.each do |test|
        puts "Test #{idx}: #{test[0]}"
        test[1].call(self)
      end
    end
  end
  
  def self.change_ruby_memory
    @buffer ||= ""
    chunk = ""
    rand(500).times {chunk << "kkkkkkkkkkkkkkkkkkkk111111111111119020220228djdhiff0-030338"}
    @buffer << chunk
    #@buffer.index('foobar')
    if @buffer.size > 900182
      puts "truncating buffer from size: #{@buffer.size}"
      @buffer = ""
    end
  end
  
  def self.assert(flag)
    raise "assertion failed" unless flag
  end
  
  TEST_LUA =%Q(function _template_inline()
local _out = {};table.insert(_out, "<h1>Hello "); table.insert(_out, tostring(user())); table.insert(_out, "</h1>"); table.insert(_out, "\\n"); 
table.insert(_out, "<br />\\n"); 
table.insert(_out, "<b>footer</b>\\n"); 
return table.concat(_out)
end)
  
  def self.simple_lua(lam, options = {})
    if USE_MY_CODE || options[:override]
      return lam.render(options)
      #puts "hi"
    else
      lua = lam.compile_template('inline', lam.load_template('inline'))
          
      state = Rufus::Lua::State.new
#      lua = lam.compile_template('inline', lam.load_template('inline'))
      if options[:locals]
        options[:locals].each_pair {|key,val| state.eval("#{key} = '#{val}'")}
      end
      yield(state) if block_given?

      state.eval(lua)
      
#      lua = lam.compile_template('inline', lam.load_template('inline'))

      res = state.eval("return _template_inline()")
      state.close
      res
    end
  end
    
  
  test "repeated simple render" do
    lam = Laminate::Template.new(:text => "<h1>Hello world</h1>\n<br />\n<b>footer</b>")
  
    2000.times do |idx|
      res = simple_lua(lam, :override => true)
      assert res =~ /Hello world/
      assert res =~ /footer/
      if idx == 100 || idx == 500 || idx == 700
        change_ruby_memory
      end
    end
  end
  
  
  test "repeated substitution render" do
    lam = Laminate::Template.new(:text => "<h1>Hello {{name}}</h1>\n<br />\n<b>footer</b>")
  
    2000.times do
      res = simple_lua(lam, :locals => {:name => 'Kirk Lazarus'},  :override => false)
      assert res =~ /Hello Kirk/
    end
  end
  
    
  test "repeat render with Ruby func call" do
    lam = Laminate::Template.new(:text => "<h1>Hello {{user()}}</h1>\n<br />\n<b>footer</b>")
  
    5000.times do |idx|
      res = simple_lua(lam, :override => true, :helpers => [RubyHelper]) do |state|
        @view = Myview.new
        Myview.send(:include, RubyHelper)
        setup_funcs(state, @view)
      end
      
      assert res =~ /Hello Tugg/
      change_ruby_memory if (idx % 100) == 0
    end
  end

  def self.setup_funcs(state, view)
    state.function("user") do
      view.user
      #Tugg"
    end
  end
  
  def self.setup_helper(state, target)
    [:profile, :user].each do |rmeth|
      state.function(rmeth.to_s) do
        target.send(rmeth)
      end
    end
    
    puts "helpers setup"
  end
  
  test "repeat render with func returning complex data" do
    puts "Starting complex data test"
    lam = Laminate::Template.new(:text => <<-ENDLUA
      {{p=profile()}}
      <h1>Hello {{p.name}}</h1>
      Your first movie was: {{p.movies[1]}}
    ENDLUA
    )
  
    5000.times do |idx|
      res = simple_lua(lam, :override => true, :helpers => [RubyHelper]) do |state|
        state.function 'profile' do
          {'name' => 'Jeff Portnoy', 'age' => 32, 'movies' => ['The Fatties','Piece \'o Shit 2']}
        end
      end
      assert res =~ /Jeff/
      change_ruby_memory if (idx % 100) == 0
    end
  end
  
  test "repeat render with scoped function" do
    lam = Laminate::Template.new(:text => <<-ENDLUA
      {{p=vodspot.simpleval()}}
      {{p}}
    ENDLUA
    )
  
    1000.times do |idx|
      res = simple_lua(lam, :helpers => [ComplexHelper.new]) do |state|
        state.eval("vodspot = {}")
        state.function 'vodspot.simpleval' do
          "secret"
        end
      end
      assert res =~ /secret/
      change_ruby_memory if (idx % 100) == 0
    end
  end
  
end

StressTest.new.run
