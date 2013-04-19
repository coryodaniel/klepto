module Klepto
  class Bot
    attr_reader :config

    def initialize(*urls, &block)
      @config = Klepto::Config.new
      @config.urls urls
      @queue  = []

      instance_eval &block

      instance_eval <<-EOS
def queue; @queue; end;
def resources; @resources; end;
EOS

      __process!
    end

    def __process!
      @resources = []

      config.urls.each do |url|
        browser   = Klepto::Browser.new

        browser.set_headers config.headers
        browser.fetch! url

        config.after_handlers[:get].each do |ah|
          ah.call(browser.page)
        end
        
        statuses = [browser.status, browser.statusx]
        statuses.push :redirect if url != browser.page.current_url
        statuses.each do |status|
          config.dispatch_status_handlers(status, browser.page)
        end

        structure = Structure.new(browser.page)

        queue.each do |instruction|
          if instruction[2]
            structure.send instruction[0], *instruction[1], &instruction[2]
          else
            structure.send instruction[0], *instruction[1]
          end
        end

        config.after_handlers[:each].each do |ah|
          ah.call(structure._hash)
        end

        resources << structure._hash
      end

      @resources
    end

    def method_missing(meth, *args, &block)
      @queue.push([meth, args, block])
    end
  end
end