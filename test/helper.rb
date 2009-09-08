require 'test/unit'
require 'rubygems'
require 'ruby-debug'

# gem install redgreen for colored test output
begin require 'redgreen'; rescue LoadError; end

#require File.join(File.dirname(__FILE__), 'boot') unless defined?(ActiveRecord)

# Add Rails-style declarative test syntax
  
class Test::Unit::TestCase
  def self.test(name, &block)
    test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
    defined = instance_method(test_name) rescue false
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end
end

$:.unshift(File.join(File.dirname(__FILE__), '../lib'))
  
# Look for Rufus-Lua parallel to Laminate (as in vendor/plugins), otherwise it must be installed as a gem.
rufus_dir = File.join(File.dirname(__FILE__), '../../rufus-lua/lib')
if File.exist?(rufus_dir)
  $:.unshift(rufus_dir)
end