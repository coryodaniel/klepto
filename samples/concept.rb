#! /usr/bin/env ruby
require 'bundler/setup'
require 'klepto'

Klepto::Bot.new do
  config.headers 'Referer' => 'http://www.twitter.com'
  config.on_http_status('5xx','4xx'){
    puts "HOLY CRAP!"
  }

  # If you want to do something with each resource, like stick it in AR
  #   go for it here...
  config.after do |resource|
    @user = User.new
    @user.name = resource[:name]
    @user.username = resource[:username]
    @user.save

    resource[:tweets].each do |tweet|
      Tweet.create(tweet)
    end
  end 

  config.urls 'https://twitter.com/justinbieber', 
              'https://twitter.com/ladygaga'

  # config.steps [
  #   [:GET, 'https://twitter.com/login'],
  #   [:POST,'https://twitter.com/sessions', 
  #     { 
  #       session: {
  #         username_or_email: 'example',
  #         password:'123456'
  #       }
  #     }
  #   ]
  # ]

  # Structure the content
  name      'h1.fullname'
  username  '.username span.screen-name'
  links     'span.url a', :list, :attr => 'href'

  tweets    'li.stream-item', :collection do |node|
    # You can access the current parent node
    twitter_id  node['data-item-id']
    
    # Defaults to innerText
    content '.content p', :css

    # get an attribute off an element
    timestamp '._timestamp', :attr => 'data-time'
    
    permalink '.time a', :css, :attr => :href
  end 
end