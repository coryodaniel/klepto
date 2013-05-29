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

      # Evaluate the block as DSL, proxy off anything that isn't on #config
      #   to a queue, then apply that queue to the top-level Klepto::Structure
      instance_eval &block

      # After DSL evaluation is queued up, put some methods onto this instance
      # and restore method_missing (for sanity sake)
      instance_eval <<-EOS
def queue; @queue; end;
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
        
        begin
          browser.fetch! url
        rescue Capybara::Poltergeist::TimeoutError => ex
          config.dispatch_timeout_handler(ex, url)
        end
        
        # Fire callbacks on GET
        config.after_handlers[:get].each do |ah|
          ah.call(browser.page)
        end
        
        # Capybara automatically follows redirects... Checking the page here
        # to see if it has changed, and if so add it on to the stack of statuses.
        # statuses is an array because it holds the actually HTTP response code and an
        # approximate code (2xx for example). :redirect will be pushed onto the stack if a
        # redirect happened.
        statuses = [browser.status, browser.statusx]
        statuses.push :redirect if url != browser.page.current_url
        
        # Dispatch all the handlers for HTTP Status Codes.
        statuses.each do |status|
          config.dispatch_status_handlers(status, browser.page)
        end
        
        # If the page was not a failure or if not aborting, structure that bad boy.
        if (browser.failure? && config.abort_on_failure?) || (config.abort_on_redirect? && statuses.include?(:redirect))
          config.after_handlers[:abort].each do |ah|
            ah.call(browser.page)
          end          
        else
          resources << __structure(browser.page)
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