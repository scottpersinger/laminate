require 'helper'
require 'laminate'
require 'erb'

class HashWithObjectAccess < Hash
  def initialize(constructor = {})
    if constructor.is_a?(Hash)
      super()
      update(constructor)
    else
      super(constructor)
    end
  end
  
  def method_missing(sym, *args)
    if sym.to_s =~ /=$/
      self[sym.to_s[0...-1].to_s] = args[0]
    else
      self[sym.to_s]
    end
  end
end

class TestFuncs  < Laminate::AbstractLuaHelper
  namespace :vodspot, :util
  
  def stylesheet_url(name)
    "/stylesheets/#{name}.css"    
  end
  
  def vodspot_videos(options)
    res = [
    {"title" => "1 Jackie Moon Does It Right", "description" => "Funniest video ever", "tags" => [{"name" => "will ferell", "url" => "/tag/will"}], "date" => Time.now.to_f},
    {"title" => "2 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f},
    {"title" => "3 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f},
    {"title" => "4 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f},
    {"title" => "5 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f},
    {"title" => "6 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f},
    {"title" => "7 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f},
    {"title" => "8 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f},
    {"title" => "9 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f},
    {"title" => "10 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f},
    {"title" => "11 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f},
    {"title" => "12 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f},
    {"title" => "13 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f},
    {"title" => "14 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f},
    {"title" => "15 Obama Stump Speech", "description" => "Is he really an American? I can't remember if Hawaii is really a state.",
      "tags" => [{"name" => "obama", "url" => "/tag/obama"}, {"name" => "politics", "url" => "/tag/politics"}], "date" => Time.now.to_f}
    ]
    res.each do |v| 
      v['url'] = "/watch/39383-#{v['title']}" 
      v['embed_tag'] = "<embed src=vodpod.com ></embed>"
      v['thumbnail_100'] = 'http://img.vpimg.net/2082747.medium100.jpg'
      v['thumbnail_160'] = 'http://img.vpimg.net/2082747.medium100.jpg'
      v['thumbnail_320'] = 'http://img.vpimg.net/2082747.medium100.jpg'
    end
    res
  end
  
  def vodspot_config(key)
    "red,green,blue"
  end
  
  def vodspot_total_videos(key)
    vodspot_videos(nil).size    
  end
  
  def time_ago(timeval)
    "a long time ago"
  end
  
  def util_remote_snippet(arg1, arg2, arg3)
    "some random html"
  end
  
  def util_split(str, sep)
    str.split(sep)
  end
end

class MyErbHelper
  def initialize
    @helper = TestFuncs.new
  end
  
  def stylesheet_url(name)
    "/stylesheets/#{name}.css"    
  end
  
  def videos(options)
    videos = @helper.vodspot_videos(options).collect {|v| HashWithObjectAccess.new(v)}
    videos.each do |v|
      if v['tags'].is_a?(Array)
        v['tags'] = v['tags'].collect {|t| HashWithObjectAccess.new(t)}
      end
    end
  end
  
  def config(key)
    "red,green,blue"
  end
  
  def total_videos(key)
    videos(nil).size    
  end
  
  def time_ago(timeval)
    "a long time ago"
  end
  
  def remote_snippet(arg1 = nil, arg2 = nil, arg3 = nil)
    "some random html"
  end
  
  def split(str, sep)
    str.split(sep)
  end
   
end

# This code attempts to benchmark a "real" template example against the same template written in Erb.

class PerformanceTest
  def initialize
    @count = 1000
    puts "Laminate test..."
    lam = laminate_test
    puts "ERB test..."
    erb = erb_test
#    if lam != erb
#      puts "Ack! Files are different"
#      show_diff(lam, erb)
#    end
  end
  
  def show_diff(left, right)
    t1 = File.open("/tmp/lamoutput", "w")
    t1.write(left)
    t1.close
    t2 = File.open("/tmp/erboutput", "w")
    t2.write(right)
    t2.close
    puts system("diff /tmp/lamoutput /tmp/erboutput")
  end
  
  def benchmark(name, count = 1)
    runtimes = []
    count.times do
      start = Time.now.to_f
      yield
      runtimes << Time.now.to_f - start
    end

    total = runtimes.inject(0) {|total, rt| total+rt}
    avg = total / runtimes.size.to_f
    
    msec = avg * 1000.0
    puts "#{name} took avergage of #{msec} millisecs for #{count} iterations"
  end
  
  # This is implemented just for ERB 
  def include(name)
    erb = ERB.new(File.read("fixtures/#{name}.erb"))
    erb.result(binding)
  end
  def time_ago(val)
    @helper.time_ago(val)
  end
  def stylesheet_url(base)
    @helper.stylesheet_url(base)
  end  
    
  def laminate_test
    template = Laminate::Template.new(:file => "fixtures/full_test.lam", :clear => true)
    output = nil
    benchmark "Laminate template",@count do
      output = template.render(:helpers => [TestFuncs.new], :timeout => 45, :wrap_exceptions => false)
    end
    output
  end
  
  def erb_test
    @helper = TestFuncs.new
    
    # Mocks
    vodspot = MyErbHelper.new
    util = MyErbHelper.new
    
    erb = ERB.new(File.read("fixtures/full_test.erb"))
    output = nil
    benchmark "ERB template", @count do
      output = erb.result(binding)
    end
    output
  end
  
end

PerformanceTest.new


