# Klepto

A mean little DSL'd capybara (poltergeist) based web crawler that stuffs data into your Rails app.

## Features 

* CSS or XPath Syntax
* Full javascript processing via phantomjs / poltergeist
* All the fun of capybara
* Scrape multiple pages with a single bot
* Scrape individuals pages with multiple 'crawlers', see Bieber example.

## Usage
Say you want a bunch of Bieb tweets! How is there not profit in that?

```ruby
# Make a bot
@bot = Klepto::Bot.new do
  # Set your selector syntax. You can change to :xpath if you are 40+ or love C#.
  syntax :css
  
  # Send some headers, confuse everyone.
  headers({
    'Referer'     => 'http://www.twitter.com'
  })  

  # The more the merrier. It takes a *splat.
  urls  'https://twitter.com/justinbieber'

  # Crawl the body of the page to get the user info
  crawl 'body' do
    # The default handler is to call .text on the scraped node.
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

@bot.start! #sweet victory, heart throb.
```



## TODOs

event handlers...
--------------------

    on_http_status(500,404) do |response, bot|
      email('admin@example.com', bot.status, bot.summary)
    end
    on_assertion_failure{ |response, bot| }
    on_invalid_resource{ |resource, bot| }

Pre-req Steps
--------------------  

    prepare [
      [:GET, 'http://example.com'],
      [:POST, 'http://example.com/login', {username: 'cory', password: '123456'}],
    ]

Page Assertions
--------------------

    assertions do
      present 'li.offer'
      present 'h3 a', :present => [:href]
      within 'li.offer' do
        present 'h3'
      end

      scrape 'h3 a' do |node|
        node.is_a_link_to_someplace_we_like
      end    
    end

Cookie Stufing
-------------------

    cookies({
      'Has Fun' => true
    })  
