/*
  CoffeeScript
  JS Lint
  PhantomJS

  Ruby 'configuration' gem
  Ruby blocks -> Javascript -> Ruby OR Javascript post processors
  Ruby blocks -> Assertion? Auto generate cucumbers? OR callbacks on node not found?
  https://github.com/ariya/phantomjs/wiki/API-Reference-WebPage

  Config.defaults {
    on(200,'2xx', :redirect){}
    on('4xx'){}
    on('5xx'){}
    on(:timeout){}
    on(:abort){}
    headers({})
    cookies({})  
    agent "Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit/534.34 (KHTML, like Gecko) Klepto/#{Klepto::Version} Safari/534.34"
  }
  Bot.new("http://google.com")do 
    config{
      # merges with Defaults, creates a Configuration
      url "http://google.com"
      auto_structure false # stops it from running structure (@bot.process! will run it)
      abort_on_failure true
      agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/534.51.22 (KHTML, like Gecko) Version/5.1.1 Safari/534.51.22";
      
      headers({})
      cookies({})

      on(200,'2xx', :redirect){}
      on('4xx'){}
      on('5xx'){}
      on(:timeout){}
      on(:abort){}

      before(:get){}
      after(:get){}
      before(:structure){}    
      after(:structure){}
    }

    structure{
      # Should yield against Proxy so method_missing and queueing isn't in Bot
    }
  end

*/
var page = require('webpage').create(),
  system = require('system'),
  lt, pt, t, currentAddress, requestedAddress;

page.settings.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/534.51.22 (KHTML, like Gecko) Version/5.1.1 Safari/534.51.22";
page.settings.loadImages = false;

page.onUrlChanged = function(targetUrl){
  currentAddress = targetUrl;
  console.log("Redirecting to: " + currentAddress);
}

page.onResourceReceived = function(resource) {
  if (resource.stage === 'end' && resource.status == 200 && resource.url == currentAddress) {
    lt = Date.now() - t;
    console.log("Crawling: " + resource.url);
    page.includeJs("http://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js", function() {
      var title = page.evaluate(function(){
        return $("title").text();
      });

      pt = Date.now() - t;
      var structure = JSON.stringify({
        title: title,
        _meta: {
          loadTime:           lt,
          parseTime:          pt,
          redirectOccurred:   (requestedAddress != resource.url),
          requestedAddress:   requestedAddress,
          currentAddress:     resource.url,
          httpCode:    resource.status
        }
      });
      system.stdout.write(structure);
      
      phantom.exit();
    });
  } else if(resource.stage === 'end' && resource.status != 200 && resource.url == currentAddress){
    console.log("Oops: " + resource.status);
    phantom.exit();
  } else {/* NOOP*/}
}

if (system.args.length === 1) {
  console.log('Usage: test.js <some URL>');
  phantom.exit(1);
} else {
  t = Date.now();
  currentAddress = requestedAddress = system.args[1];
  page.open(requestedAddress);
}