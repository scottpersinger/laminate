require 'helper'
require 'logger'
require 'laminate'
require 'laminate/timeouts'

class SecurityTest < Test::Unit::TestCase
  def setup
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::FATAL
  end
  
  test "laminate_excludes_lua_builtin_funcs" do

    assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{os.clock()}}", :logger => @logger).render(:raise_errors => true)
    end

    assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{os.execute('ls')}}", :logger => @logger).render(:raise_errors => true)
    end
    
    assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{ io.stdout:write('hello world') }}", :logger => @logger).render(:raise_errors => true)
    end

    assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{ require ('io') }}", :logger => @logger).render(:raise_errors => true)
    end
    
    assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{ dofile('fixtures/snippet.lua') }}", :logger => @logger).render(:raise_errors => true)
    end

    assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{ collectgarbage('stop') }}", :logger => @logger).render(:raise_errors => true)
    end
       
    assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{ x = #_G }}", :logger => @logger).render(:raise_errors => true)
    end

    assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{ x = getfenv(0) }}", :logger => @logger).render(:raise_errors => true)
    end

    assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{ y = getmetatable('') }}", :logger => @logger).render(:raise_errors => true)
    end

    assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{ setfenv(1, {}) }}", :logger => @logger).render(:raise_errors => true)
    end
            assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{ setmetatable(string, {}) }}", :logger => @logger).render(:raise_errors => true)
    end
    
    # We disable string:rep because it can use too much memory
    assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{ if string.rep(' ', 3) ~= '   ' then error('overridde'); end }}", :logger => @logger).render(:raise_errors => true)
    end
    
  end

  test "script timeouts" do
    puts "If this test does not break after 20 secs then Lua timeouts are NOT working properly"
    start = Time.now
    assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{ for i=1,1e12 do f = 'hello'; end }}", :logger => @logger).render(:raise_errors => true, :timeout => 10)
    end
    cost = Time.now - start
    assert cost < 30
    
    # Attack the alarm function
    start = Time.now
    assert_raise Laminate::TemplateError do
      Laminate::Template.new(:text => "{{ alarm(0) }} {{ for i=1,1e12 do f = 'hello'; end }}", :logger => @logger).render(:raise_errors => true, :timeout => 10)
    end
    cost = Time.now - start
    assert cost < 30
    
  end
  
  test "print function redefined as template output" do
    #res = Laminate::Template.new(:text => "{{ print('hello world') }} and {{ ',and goodbye' }}").render
    #puts res
    #assert res =~ /hello world,and goodbye/
  end
  
end

