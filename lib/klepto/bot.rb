module Klepto
  class Bot
    def initialize(*args, &block)
      @syntax     = :css
      @is_dry_run = false
      @urls       = []
      @crawlers   = []
      @browser    = Klepto::Browser.new
      Docile.dsl_eval(self, &block) if block_given?
    end

    attr_reader :browser, :crawlers

    def dry_run!
      @is_dry_run = true
    end

    def dry_run?
      !!@is_dry_run
    end

    def syntax(kind=nil)
      @syntax = kind unless kind.nil?
      @syntax
    end

    def headers(_headers)
      @browser.set_headers(_headers)
    end

    def url(*args)
      @urls += args
    end
    alias :urls :url

    def crawl(scope, options={}, &block)
      options[:syntax] = @syntax
      @crawlers << Klepto::Crawler.new(scope, options, &block)
    end

    def start!
      @urls.each do |url|
        browser.fetch!(url)
        @crawlers.each do |crawler|
          crawler.crawl browser.page
        end
      end

      @crawlers.each do |crawler|
        if dry_run?
          pp crawler.resources
        else
          crawler.persist!
        end
      end
    end

  end
end