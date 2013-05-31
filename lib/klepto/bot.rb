module Klepto
  class Bot
    attr_reader :config
    @@_bots = {}
    class << self
      def run(name,*urls)
        urls.each do |url|
          @@_bots[name].parse! url
        end
      end
      def make(name, &block)
        @@_bots[name] = Klepto::Bot.new(&block)
      end
    end

    def initialize(*urls, &block)
      @config = Klepto::Config.new
      @config.urls urls
      @queue  = []
      @pages  = {}

      # Evaluate the block as DSL, proxy off anything that isn't on #config
      #   to a queue, then apply that queue to the top-level Klepto::Structure
      instance_eval &block

      # After DSL evaluation is queued up, put some methods onto this instance
      # and restore method_missing (for sanity sake)
      instance_eval <<-EOS
def queue; @queue; end;
def pages; @pages; end;
def parse!(*_urls); __process!(*_urls); end;
def resources; @resources; end;
def method_missing(meth, *args, &block)
  raise NoMethodError.new("undefined method: Klepto::Bot#" + meth.to_s)
end
EOS

      __process!
    end

    # Structure all the pages
    def __process!(*_urls)
      @resources = []

      (_urls + config.urls).each do |url|
        browser   = Klepto::Browser.new

        browser.set_headers config.headers
        #browser.set_driver  config.driver

        # Call before(:each) handlers...
        config.before_handlers[:each].each { |bh| 
          bh.call(url, browser) 
        }
        
        begin
          browser.fetch! url

          @pages[url] = browser.page if config.keep_pages

          # Fire callbacks on GET
          config.after_handlers[:get].each do |ah|
            ah.call(browser.page, browser, url)
          end
                  
          # Dispatch all the handlers for HTTP Status Codes.
          browser.statuses.each do |status|
            config.dispatch_status_handlers(status, browser.page)
          end
          
          # If the page was not a failure or if not aborting, structure that bad boy.
          if (browser.failure? && config.abort_on_failure?) || (config.abort_on_redirect? && browser.was_redirected?)
            config.after_handlers[:abort].each do |ah|
              ah.call(browser.page,{
                browser_failure:     browser.failure?,
                abort_on_failure:   config.abort_on_failure?,
                abort_on_redirect:  config.abort_on_redirect?,
                redirect:           browser.was_redirected?
              })
            end          
          else
            @resources << __structure(browser.page)
          end          
        rescue Capybara::Poltergeist::TimeoutError => ex
          config.dispatch_timeout_handler(ex, url)
        end
      end

      @resources
    end

    def __structure(context)
      structure = Structure.new(context)

      # A queue of DSL instructions
      queue.each do |instruction|
        if instruction[2]
          structure.send instruction[0], *instruction[1], &instruction[2]
        else
          structure.send instruction[0], *instruction[1]
        end
      end

      # Call after(:each) handlers...
      config.after_handlers[:each].each { |ah| ah.call(structure._hash) }
    
      structure._hash
    end

    def method_missing(meth, *args, &block)
      @queue.push([meth, args, block])
    end
  end
end