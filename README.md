# Klepto

A mean little DSL'd capybara (poltergeist) based web crawler that stuffs data into ActiveRecord or wherever(TM).

## Features 

* CSS or XPath Syntax
* Full javascript processing via phantomjs / poltergeist
* All the fun of capybara
* Scrape multiple pages with a single bot
* Scrape individuals pages with multiple 'crawlers', see Bieber example.
* Pretty nifty DSL
* Test coverage!

## Usage (All your content are belong to us)
Say you want a bunch of Bieb tweets! How is there not profit in that?

```ruby
# Crawl a web site or multiple. Structure#crawl takes a *splat!
@structures = Klepto::Structure.crawl("https://twitter.com/justinbieber"){
  # By default, it uses CSS selectors
  name      'h1.fullname'

  # If you love C# or you are over 40, XPath is an option!
  username "//span[contains(concat(' ',normalize-space(@class),' '),' screen-name ')]", :syntax => :xpath
  
  # By default Klepto uses the #text method, you can pass an :attr to use instead...
  #   or a block that will receive the Capybara Node or Result set.
  tweet_ids 'li.stream-item', :match => :all, :attr => 'data-item-id'
  
  # Want to match all the nodes for the selector? Pass :match => :all
  links 'span.url a', :match => :all do |node|
    node[:href]
  end

  # Nested structures? Let klepto know this is a resource
  last_tweet 'li.stream-item', :as => :resource do
    twitter_id do |node|
      node['data-item-id']
    end
    content '.content p'
    timestamp '._timestamp', :attr => 'data-time'
    permalink '.time a', :attr => :href
  end      

  # Multiple Nested structures? Let klepto know this is a collection of resources
  tweets    'li.stream-item', :as => :collection do
    twitter_id do |node|
      node['data-item-id']
    end
    tweet '.content p', :css
    timestamp '._timestamp', :attr => 'data-time'
    permalink '.time a', :css, :attr => :href
  end     

  # If you want to do something with each resource, like stick it in AR
  #   go for it here...
  after_crawl do |resource|
    @user = User.new
    @user.name = resource[:name]
    @user.username = resource[:username]
    @user.save

    resource[:tweets].each do |tweet|
      Tweet.create(tweet)
    end
  end     
}

#An array of hashes is returned, store those bad boys you heart throb!
@structures.each do |structure|
  TwitterClone.create(structure) #=> Profit!
end
```

## Got a string of HTML you don't need to crawl first?

```ruby
@html = Capybara::Node::Simple.new(@html_string)
@structure = Klepto::Structure.build(@html){
  # inside the build method, everything works the same as Structure.crawl
  name      'h1.fullname'
  username  'span.screen-name'

  links 'span.url a', :match => :all do |node|
    node[:href]
  end

  tweets    'li.stream-item', :as => :collection do
    twitter_id do |node|
      node['data-item-id']
    end
    tweet '.content p', :css
    timestamp '._timestamp', :attr => 'data-time'
    permalink '.time a', :css, :attr => :href
  end       
}
```

## Extra Configuration
```ruby
config = {
  :headers => {
    'Referer'     => 'http://www.twitter.com',
    'X-Sup-Dawg'  => "Yo, What's up?"
  }
}
@structures = Klepto::Structure.crawl("https://twitter.com/justinbieber",config){
  #... yada, yada
}
```



## Stuff I'm going to add.
sexier config...
------------------
```ruby
Klepto::Structure.crawl("https://twitter.com/justinbieber"){
  config.headers({
    "Referer" => "http://example.com"
  })
}

```

event handlers...
--------------------
```ruby
on_http_status(500,404) do |response, bot|
  email('admin@example.com', bot.status, bot.summary)
end
on_assertion_failure{ |response, bot| }
on_invalid_resource{ |resource, bot| }
```

Pre-req Steps
--------------------  
```ruby
prepare [
  [:GET, 'http://example.com'],
  [:POST, 'http://example.com/login', {username: 'cory', password: '123456'}],
]
```

Page Assertions
--------------------
```ruby
assertions do
  #presence and value assertions...
end
```

Cookie Stuffing
-------------------
```ruby
cookies({
  'Has Fun' => true
})  
```