require 'spec_helper'

describe Klepto::Bot, :vcr => {:record => :new_episodes} do
  before(:each) do
    @bot = Klepto::Bot.new
  end

  it 'should know if it is a dry run' do
    @bot.dry_run?.should be false
    @bot.dry_run!
    @bot.dry_run?.should be true
  end

  it 'should be able to set the selection syntax' do
    @bot.syntax(:xpath)
    @bot.syntax.should be(:xpath)
  end

  it 'should be able to read the selection syntax' do
    @bot.syntax.should be(:css)
  end

  it 'should be able to set request headers' do
    @bot.should respond_to(:headers)
  end

  it 'should be able to set a list of URLs to crawl' do
    @bot.url 'http://www.google.com'
    @bot.urls.should include('http://www.google.com')
    @bot.urls 'http://twitter.com', 'http://facebook.com'
    @bot.urls.should include('http://twitter.com')
    @bot.urls.should include('http://facebook.com')
  end

  it 'should be able to add crawlers' do
    @bot.crawl('div'){}
    @bot.instance_variable_get("@crawlers").should have(1).crawler
    @bot.instance_variable_get("@crawlers").first.should be_kind_of(Klepto::Crawler)
  end
end