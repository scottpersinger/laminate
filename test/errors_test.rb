require 'helper'
require 'logger'
require 'laminate'

module TestFuncs
  def func_raises_error
    raise "Error, you no call this func!"
  end
  
  def post_processed_func(arg1, arg2)
    raise "Ruby-land error from: #{arg1}, #{arg2}"
  end  
end

class ErrorsTest < Test::Unit::TestCase
  def setup
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::FATAL
  end
  
  test "simple" do
  end
  
  test "laminate_compile_errors" do
    template = "<h1>heading</h1>{{color%><% System.exit}}"
    lam = Laminate::Template.new(:text => template, :logger => @logger)
    
    assert !lam.compile
    assert lam.get_errors.size > 0
    
    lam.render
    
    assert_raise Laminate::TemplateError do
      lam.render!
    end
    
    template =<<-ENDTEMP
      <html>
      <body>
        <h1>Heading<\/h1>
        {{loop error}}
      <\/body>
      <\/html>
    ENDTEMP
    
    lam = Laminate::Template.new(:text => template, :logger => @logger)
    res = lam.render
    assert res =~ /Template.*error/i
  end

    
  test "unclosed_block_errors" do
    # Template has no {{end}} clause
    template = "<h1>heading<\/h1>\n{{for i,video in ipairs(videos) do}}\n<p>\n{{video.title}}\n{{end}}<\/p>{{if true then}}\n<b>nice<\/b>"
    lam = Laminate::Template.new(:text => template, :logger => @logger)

    res = lam.render
    assert (res =~ /expecting \{\{end\}\}/ || res =~ /'end' expected/)    
  end
  
  test "lua_syntax_error" do
    template = "heading\n{{if _}}\nloop line\n{{end}}"
    lam = Laminate::Template.new(:text => template, :logger => @logger)
    
    assert_raise Laminate::TemplateError do
      lam.render!
    end    
  end
 
  test "lua runtime error" do
    lam = Laminate::Template.new(:text => "hello {{world()}}", :logger => @logger)
    
    assert lam.render =~ /Template.*error/i
  end
  
  test "include_error" do
    lam = Laminate::Template.new(:file => File.dirname(__FILE__) + "/fixtures/errortest.lam", :logger => @logger)

    puts "Expected error in included template"
    puts lam.render
  end

  test "include runtime error" do
    lam = Laminate::Template.new(:file => File.dirname(__FILE__) + "/fixtures/errortest.lam", :logger => @logger)

    puts "Expected runtime error in included template"
    puts lam.render(:locals => {:error_file => '_badinclude2'})
  end
  
  test "ruby exception converted to TemplateError" do
    template =<<-ENDTEMP
    line1
    line2  
    {{ func_raises_error() }}
    line 4
    ENDTEMP
    lam = Laminate::Template.new(:text => template, :logger => @logger)
    
    assert_raise Laminate::TemplateError do
     lam.render!(:helpers => [TestFuncs])
    end
    
    assert lam.render(:helpers => [TestFuncs]) =~ /error at line 3/i
    
    # Test without exception wrapping
    assert_raise RuntimeError do
      assert lam.render!(:helpers => [TestFuncs], :wrap_exceptions => false)
    end

    lua =<<-ENDLUA
    line 1
    line 2
    line 3
    {{ post_processed_func('foo', 'bar') }}
    ENDLUA
    
    lam = Laminate::Template.new(:text => lua, :logger => @logger)
    assert_raise Laminate::TemplateError do
     lam.render!(:helpers => [TestFuncs])
    end

    puts lam.render(:helpers => [TestFuncs])
  end
  
end

