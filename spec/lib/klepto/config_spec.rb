require 'spec_helper'

describe Klepto::Config do  
  before(:each) do
    @config = Klepto::Config.new
    @config.headers({'Referer' => 'http://example.com'})
    @config.urls 'http://example.com', 'http://www.iana.org'
  end

  it 'should be able to set headers' do
    @config.headers['Referer'].should eq('http://example.com')
  end

  it 'should be able to set URLs' do
    @config.urls.should == ['http://example.com', 'http://www.iana.org']
  end

  pending 'should be able to set cookies'
  pending 'should be able to set steps'
  pending 'should be able to set assertions'
  pending 'should be able to set on_http_status handler'
  pending 'should be able to set on_failed_assertion handler'
  pending 'should be a sexier config' do
    # Klepto::Structure.crawl("https://twitter.com/justinbieber"){
    #   config.headers({
    #     "Referer" => "http://example.com"
    #   })
    # }
  end
end