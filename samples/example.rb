#! /usr/bin/env ruby
require 'bundler/setup'
require 'klepto'

@bot = Klepto::Bot.new do
  syntax :css
  dry_run!

  headers({
    'Referer'     => 'http://www.twitter.com',
    'User-Agent'  => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/534.51.22 (KHTML, like Gecko) Version/5.1.1 Safari/534.51.22"

  })  

  # Lootin' them bieb tweets
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