module Klepto
  class Config
    attr_reader :after_handlers
    attr_reader :before_handlers
    
    def initialize
      @headers = {}
      @abort_on_failure = true
      @abort_on_redirect = false
      @after_handlers   = {
        :structure => [], #after each call to
        :get  => [], #after GET, before structure
        :abort=> []  #after abort
      }
      @before_handlers  = {:get => []}
      @status_handlers  = {}
      @handlers = {}
    end

    # TODO: DRY up handlers...
    # def dispatch(group, handler, *args)
    #   @handlers[group] ||= {}
    #   @handlers[group][handler] ||= []
    #   @handlers[group][handler].each{|handler| handler.call(*args)}
    # end

    # def driver(_driver=nil)
    #   @default_driver = _driver if _driver
    #   @default_driver
    # end

    def headers(_headers=nil)
      @headers = _headers if _headers
      @headers
    end

    def has_timeout_handler?
      @status_handlers[:timeout] && @status_handlers[:timeout].any?
    end

    def abort_on_failure?
      !!@abort_on_failure
    end

    def abort_on_redirect?
      !!@abort_on_redirect
    end

    # 4xx, 5xx
    def abort_on_failure(aof)
      @abort_on_failure = aof
    end

    def abort_on_redirect(aor)
      @abort_on_redirect = aor
    end

    def status_handler(status)
      @status_handlers[status] || []
    end    

    def on_http_timeout(&block)
      @status_handlers[:timeout] ||= []
      @status_handlers[:timeout].push block
    end

    def on_http_status(*statuses,&block)
      statuses.each do |status|
        @status_handlers[status] ||= []
        @status_handlers[status].push block
      end
    end

    def after(which = :structure, &block)
      @after_handlers[which] ||= []
      @after_handlers[which].push block
    end

    def before(which, &block)
      @before_handlers[which] ||= []
      @before_handlers[which].push block
    end    

    def url(url=nil)
      @url = url if url
      @url
    end
  end
end