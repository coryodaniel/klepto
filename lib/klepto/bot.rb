module Klepto
  class Bot
    attr_reader :config

    def initialize(url=nil, &block)
      @config = Klepto::Config.new
      @config.url url
      @queue  = []
      @browser = Klepto::Browser.new
      
      # Evaluate the block as DSL, proxy off anything that isn't on #config
      #   to a queue, then apply that queue to the top-level Klepto::Structure
      instance_eval &block

      # After DSL evaluation is queued up, put some methods onto this instance
      # and restore method_missing (for sanity sake)
      instance_eval <<-EOS
def queue; @queue; end;
def browser; @browser; end;
def url=(_url); @config.url(_url); end;
def structure; @structure; end;
def method_missing(meth, *args, &block)
  raise NoMethodError.new("undefined method: Klepto::Bot#" + meth.to_s)
end
EOS

      __process!
    end

    # Structure all the pages
    def __process!
      @structure = nil
      @browser.set_headers @config.headers
      #browser.set_driver  config.driver

      # Call before(:each) handlers...
      @config.before_handlers[:each].each { |bh| 
        bh.call(url, browser) 
      }
      
      begin
        @browser.fetch! @config.url

        # Fire callbacks on GET
        @config.after_handlers[:get].each do |ah|
          ah.call(@browser.page, @browser, @config.url)
        end
                
        # Dispatch all the handlers for HTTP Status Codes.
        @browser.statuses.each do |status|
          @config.dispatch_status_handlers(status, @browser.page)
        end
        
        # If the page was not a failure or if not aborting, structure that bad boy.
        if (@browser.failure? && @config.abort_on_failure?) || (@config.abort_on_redirect? && @browser.was_redirected?)
          @config.after_handlers[:abort].each do |ah|
            ah.call(browser.page,{
              browser_failure:    @browser.failure?,
              abort_on_failure:   @config.abort_on_failure?,
              abort_on_redirect:  @config.abort_on_redirect?,
              redirect:           @browser.was_redirected?
            })
          end          
        else
          @structure = __structure(@browser.page)
        end          
      rescue Capybara::Poltergeist::TimeoutError => ex
        config.dispatch_timeout_handler(ex, url)
      end

      @structure
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