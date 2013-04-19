module Klepto
  class Config
    attr_reader :after_handlers

    def initialize
      @headers = {}
      @abort_on_failure = true
      @urls    = []
      @after_handlers   = {
        :each => [], 
        :get  => [],
        :abort=> []
      }
      @before_handlers  = {:each => []}
      @status_handlers  = {}
      @handlers = {}
    end

    # TODO: DRY up handlers...
    # def dispatch(group, handler, *args)
    #   @handlers[group] ||= {}
    #   @handlers[group][handler] ||= []
    #   @handlers[group][handler].each{|handler| handler.call(*args)}
    # end

    def headers(_headers=nil)
      @headers = _headers if _headers
      @headers
    end

    def abort_on_failure?
      !!@abort_on_failure
    end

    # 4xx, 5xx
    def abort_on_failure(aof)
      @abort_on_failure = aof
    end

    def on_http_status(*statuses,&block)
      statuses.each do |status|
        @status_handlers[status] ||= []
        @status_handlers[status].push block
      end
    end

    def dispatch_status_handlers(status, page)
      handlers = @status_handlers[status]
      if handlers.present?
        @status_handlers[status].each do |handler|
          handler.call(page)
        end
      end
    end

    def after(which = :each, &block)
      @after_handlers[which] ||= []
      @after_handlers[which].push block
    end

    def before(which, &block)
      @before_handlers[which] ||= []
      @before_handlers[which].push block
    end    

    def url(*args)
      @urls += args
      @urls.flatten!
      @urls.uniq!
      @urls
    end
    alias :urls :url    
  end
end