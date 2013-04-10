require 'spec_helper'

describe Klepto do
  it "should have a version" do
    Klepto::VERSION.should_not be_nil
  end
end

describe 'Scraping pages', :skip => false do
  before(:each) do
    @bot = Klepto::Bot.new do
      syntax :css

      headers({
        'Referer'     => 'https://twitter.com',
        'User-Agent'  => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/534.51.22 (KHTML, like Gecko) Version/5.1.1 Safari/534.51.22"
      })  

      urls  'https://twitter.com/justinbieber'

      crawl 'body' do
        scrape "h1.fullname", :name
        scrape '.username span.screen-name', :username
        save do |params|
          user = User.find_by_name(params[:username]) || User.new
          user.update_attributes params
        end
      end

      crawl 'li.stream-item' do
        scrape do |node|
          {:twitter_id => node['data-item-id']}
        end
        
        scrape '.content p', :content

        scrape '._timestamp' do |node|
          {timestamp: node['data-time']}
        end

        scrape '.time a' do |node|
          {permalink: node[:href]}
        end
            
        save do |params|
          tweet = Tweet.find_by_twitter_id(params[:twitter_id]) || Tweet.new
          tweet.update_attributes params
        end
      end  
    end

    @bot.start!
  end

  it 'should have collected some resources' do
    @bot.crawlers.should have(2).crawlers
    @bot.crawlers.first.resources.should have(1).user
  end

  it 'should persist resources' do
    User.count.should be(1)
    Tweet.count.should_not be(0)
  end
end  