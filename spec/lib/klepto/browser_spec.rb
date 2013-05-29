require 'spec_helper'

describe Klepto::Browser, :vcr => {:record => :new_episodes} do  
  before(:each) do
    @browser = Klepto::Browser.new
    @browser.set_headers({
      'Referer'     => 'http://www.example.com'
    })
  end

  it 'should be able to fetch a page' do
    @page = @browser.fetch! 'http://www.example.com'
    @page.status_code.should be(200)
  end

  # it 'should use poltergeist by default' do
  #   @browser.use_driver.should == :poltergeist
  # end
end