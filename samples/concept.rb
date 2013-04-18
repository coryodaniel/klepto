#! /usr/bin/env ruby
require 'bundler/setup'
require 'klepto'

@structure = Klepto::Structure.crawl('https://twitter.com/justinbieber')
  config.headers 'Referer' => 'http://www.twitter.com'

  config.steps [
    [:GET, 'https://twitter.com/login'],
    [:POST,'https://twitter.com/sessions', 
      { 
        session: {
          username_or_email: 'example',
          password:'123456'
        }
      }
    ]
  ]
  config.urls 'https://twitter.com/justinbieber', 
              'https://twitter.com/ladygaga'
  # config.cookies 'jsession' => 'abcdefg1234567890'        
  # config.on_http_status(500,404){}
  # assertions do
  # end
  # config.on_failed_assertion(){}


  # Structur the content
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

# @resources = @structure.parse! #=> Array[Hash]
# @resources.each do |resource|
#   User.create(resource)
# end