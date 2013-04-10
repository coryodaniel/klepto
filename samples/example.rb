#! /usr/bin/env ruby
require 'bundler/setup'
require 'klepto'

@bot = Klepto::Bot.new do
  dry_run!
  syntax :css

  headers({
    'Referer'     => 'http://www.retailmenot.com',
    'User-Agent'  => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/534.51.22 (KHTML, like Gecko) Version/5.1.1 Safari/534.51.22"
  })  

  urls  'http://www.retailmenot.com/view/gap.com',
        'http://www.retailmenot.com/view/kohls.com'

  crawl 'body' do
    scrape "#store_info h1", :name
    scrape '.coupon_count strong', :savings
    save do |params|
      #store = Store.find_by_name(params[:name]) || Store.new
      #store.update_attributes params
    end
  end

  crawl 'li.offer' do
    scrape do |node|
      {:remote_id => node['data-offerid']}
    end
    scrape 'h3 a', :title
    scrape '.description p' do |node|
      {description: node.text.downcase.capitalize}
    end

    scrape 'h3 a' do |node|
      {url: node[:href]}
    end
        
    save do |params|
      #coupon = Coupon.find_by_remote_id(params[:remote_id]) || Coupon.new
      #coupon.update_attributes params
    end
  end  
end

@bot.start!