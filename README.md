# Klepto TODOs

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
