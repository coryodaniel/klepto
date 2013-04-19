require 'rubygems'
require 'bundler/setup'
require 'debugger'
require 'simplecov'
SimpleCov.start do
  add_filter "spec"
end

require 'klepto'
require 'vcr'
require 'orm/active_record'

def page(url="http://example.com")
  Capybara::Node::Simple.new(open(url).read)
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :fakeweb
  c.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.before(:all) { TestMigration.up }
  config.after(:each){ 
    User.delete_all
    Tweet.delete_all
    StatusLog.delete_all
  }
  config.after(:all) { TestMigration.down }
  config.treat_symbols_as_metadata_keys_with_true_values = true
  #config.filter_run_including :only => true
end