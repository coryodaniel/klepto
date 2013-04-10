require 'docile'
module Klepto
  class Crawler

    def initialize(scope,options={},&block)
      @resources = []
      @limit  = options[:limit] 
      @skip   = options[:skip]
      @syntax = options[:syntax]
      @scope  = scope
      @designations = []
      
      Docile.dsl_eval(self, &block) if block_given?
    end   
    attr_accessor :resources
    attr_reader :scope, :syntax

    def scrape(selector=nil, assignee=nil, &block)
      raise Exception if assignee.nil? && !block_given?
      raise Exception if !assignee.nil? && block_given?
      designate(:first, selector, assignee, &block)
    end

    def scrape_all(selector, assignee=nil, &block)
      raise Exception if assignee.nil? && !block_given?
      raise Exception if !assignee.nil? && block_given?
      designate(:all, selector, assignee, &block)
    end

    def save(&block)
      @resource_handler = block
    end

    def crawl(page)
      page.all(syntax, scope).each do |selection|
        params = {}
        @designations.each do |first_or_all, selector, assignee, handler|
          if selector.nil?
            attribs = handler.call selection
            params.merge!( attribs )            
          elsif first_or_all == :first
            node = selection.first(syntax, selector)
            if assignee
              params[assignee] = node.text
            else
              attribs = handler.call node
              params.merge!( attribs )
            end
          else
            nodes = selection.all(syntax, selector)
            attribs = handler.call nodes
            params.merge!( attribs )
          end
        end
        @resources << params
      end

      if @resource_handler
        @resources.each {|resource| @resource_handler.call(resource)}
      end

      @resources
    end

    protected
      def designate(count, selector, assignee, &block)
        @designations << [count, selector, assignee, block]
      end
  end
end