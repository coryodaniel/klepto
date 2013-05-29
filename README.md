# Klepto

A mean little DSL'd capybara (poltergeist) based web scraper that structures data into ActiveRecord or wherever(TM).

## Features 

* CSS or XPath Syntax
* Full javascript processing via phantomjs / poltergeist
* All the fun of capybara
* Scrape multiple pages with a single bot
* Pretty nifty DSL
* Test coverage!

## Installing
You need at least PhantomJS 1.8.1.  There are *no other external
dependencies* (you don't need Qt, or a running X server, etc.)

### Mac ###

* *Homebrew*: `brew install phantomjs`
* *MacPorts*: `sudo port install phantomjs`
* *Manual install*: [Download this](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.8.1-macosx.zip&can=2&q=)

### Linux ###

* Download the [32
bit](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.8.1-linux-i686.tar.bz2&can=2&q=)
or [64
bit](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.8.1-linux-x86_64.tar.bz2&can=2&q=)
binary.
* Extract the tarball and copy `bin/phantomjs` into your `PATH`

### Windows ###
* Download the [precompiled binary](http://phantomjs.org/download.html) for Windows

### Manual compilation ###

Do this as a last resort if the binaries don't work for you. It will
take quite a long time as it has to build WebKit.

* Download [the source tarball](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.8.1-source.zip&can=2&q=)
* Extract and cd in
* `./build.sh`

(See also the [PhantomJS building guide](http://phantomjs.org/build.html).)

Then put klepto in your gemfile.

```ruby
gem 'klepto', '>= 0.2.5'
```



## Usage (All your content are belong to us)
Say you want a bunch of Bieb tweets! How is there not profit in that?

```ruby
# Fetch a web site or multiple. Bot#new takes a *splat!
@bot = Klepto::Bot.new("https://twitter.com/justinbieber"){
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
  # Does bieber, tweet to much? Maybe. Lets only get the new stuff kids crave.
  tweets    'li.stream-item', :as => :collection, :limit => 10 do
    twitter_id do |node|
      node['data-item-id']
    end
    tweet '.content p', :css
    timestamp '._timestamp', :attr => 'data-time'
    permalink '.time a', :css, :attr => :href
  end     

  # Set some headers, why not.
  config.headers({
    'Referer'     => 'http://www.twitter.com'
  })  

  # on_http_status can take a splat of statuses or ~statuses(4xx,5xx)
  #   you can also have multiple handlers on a status
  #   Note: Capybara automatically follows redirects, so the statuses 3xx
  #   are never present. If you want to watch for a redirect pass see below
  config.on_http_status(:redirect){
    puts "Something redirected..."
  }
  config.on_http_status(200){
    puts "Expected this, NBD."
  }

  config.on_http_status('5xx','4xx'){
    puts "HOLY CRAP!"
  }

  config.after(:get) do |page|
    # This is fired after each HTTP GET. It receives a Capybara::Node
  end  

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
  end #=> Profit!
}

# You can get an array of hashes(resources), so if you wanted to do something else 
# you could do it here...
@bot.resources.each do |resource|
  pp resource
end
```

## Got a string of HTML you don't need to crawl first?

```ruby
@html = Capybara::Node::Simple.new(@html_string)
@structure = Klepto::Structure.build(@html){
  # inside the build method, everything works the same as Bot.new
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

## Configuration Options
* config.headers - Hash; Sets request headers
* config.urls    - Array(String); Sets URLs to structure
* config.abort_on_failure - Boolean(Default: true); Should structuring be aborted on 4xx or 5xx

## Callbacks & Processing

* before
  * n/a
* after
  * :each (resource, Hash) - called for each resource parsed
  * :get (page, Capybara::Node) - called after each HTTP GET
  * :abort (page, Capybara::Node) - called after a 4xx or 5xx if config.abort_on_failure is true (default)


## Stuff I'm going to add.
* Ensure after(:each) work at resource/collection level as well
* Add after(:all)
* :if, :unless for as: (:collection|:resource) to. context should be captured node that block is run against
* Access to hash from within a block (for bulk assignment of other attributes) ?
* config.allow_rescue_in_block #should exceptions in blocks be auto rescued with nil as the return value
* :default should be able to take a proc

Async 
--------
-> https://github.com/igrigorik/em-synchrony

Cookie Stuffing
-------------------
```ruby
cookies({
  'Has Fun' => true
})  
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
on_assertion_failure{ |response, bot| }
```

Structure
:if
unless: lambda{|node| node.class.include?("newsflash")}