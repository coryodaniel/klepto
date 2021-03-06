require 'spec_helper'

describe Klepto::Config do  
  before(:each) do
    @config = Klepto::Config.new
    @config.headers({'Referer' => 'http://example.com'})
    @config.url 'http://example.com'
    @config.on_http_status(200){
      "Its 200"
    }
    @config.on_http_status('2xx'){
      "Its 2xx"
    }
    @config.on_http_status('5xx','4xx'){
      "Its crazy."
    }
    #@config.driver :cool_driver
    @config.abort_on_failure(false)
  end

  it 'should be able to set headers' do
    @config.headers['Referer'].should eq('http://example.com')
  end

  # it 'should default to poltergeist as the driver' do
  #   @config.driver.should == :cool_driver
  # end

  it 'should have a 2xx status handler' do
    @config.instance_variable_get("@status_handlers")['2xx'].first.call.should eq ('Its 2xx')
  end

  it 'should have a 200 status handler' do
    @config.instance_variable_get("@status_handlers")[200].first.call.should eq ('Its 200')
  end

  it 'should have a 4xx and 5xx status handler' do
    @config.instance_variable_get("@status_handlers")['5xx'].first.call.should eq ('Its crazy.')
    @config.instance_variable_get("@status_handlers")['4xx'].first.call.should eq ('Its crazy.')
  end

  it 'should be able to set a URL' do
    @config.url.should == 'http://example.com'
  end

  it 'should have an abort on 4xx/5xx option' do
    @config.instance_variable_get("@abort_on_failure").should be false
  end

  pending 'should be able to set cookies'
  pending 'should be able to set steps'
  pending 'should be able to set assertions'
  pending 'should be able to set on_failed_assertion handler'
end