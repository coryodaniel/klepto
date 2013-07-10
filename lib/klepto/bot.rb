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
def process!; __process!; end;
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
      @browser.set_driver  @config.driver

      @config.before_handlers[:get].each { |bh| 
        bh.call(@browser,@config.url) 
      }
      
      begin
        @browser.fetch! @config.url

        # Fire callbacks on GET
        @config.after_handlers[:get].each do |ah|
          ah.call(@browser, @config.url)
        end

        if @browser.was_redirected?
          @config.status_handler(:redirect).each {|sh| sh.call(:redirect, @browser) }

          if @config.abort_on_redirect?
            @config.after_handlers[:abort].each {|ah| ah.call(@browser) }
            return
          end
        end
                
        # Dispatch all the handlers for HTTP Status Codes.
        @browser.statuses.each do |status|
          @config.status_handler(status).each {|sh| sh.call(status, @browser) }
        end
        
        # This is here to debug, having a weird issue with getting a 200 and sometimes
        #   returning @browser.failure? => true
        sleep_counter = 0
        while @browser.status.nil? && sleep_counter < @config.sleep_tries
          sleep_counter +=1
          sleep @config.sleep
        end

        # If the page was not a failure or if not aborting, structure that bad boy.
        if (@browser.failure? && @config.abort_on_failure?) 
          @config.after_handlers[:abort].each {|ah| ah.call(@browser) }
        else
          @structure = __structure(@browser.page)
        end          
      rescue Capybara::Poltergeist::TimeoutError => ex
        if @config.has_timeout_handler?
          @config.status_handler(:timeout).each{|th| th.call(ex, @browser, @config.url) }
        else
          raise ex
        end
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
      config.after_handlers[:structure].each { |ah| ah.call(structure._hash) }
    
      structure._hash
    end

    def method_missing(meth, *args, &block)
      @queue.push([meth, args, block])
    end
  end
end