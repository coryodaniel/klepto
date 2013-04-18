module Klepto
  class Structure
   def self.build(_context=nil, _parent=nil, &block)
      hb = Structure.new(_context, _parent)
      hb.instance_eval &block
      if hb._after_handler
        hb._after_handler.call(hb._hash)
      end

      hb._hash
    end

    def self.crawl(*urls, &block)
      config = urls.last.is_a?(Hash) ? urls.pop : {}
      resources = []
      urls.each do |url|
        browser   = Klepto::Browser.new
        browser.set_headers config[:headers]
        browser.fetch! url
        resources << Structure.build(browser.page, &block)
      end 
      resources
    end

    attr_reader :_parent
    attr_reader :_hash
    attr_reader :_context
    attr_reader :_after_handler

    def initialize(_context=nil, _parent=nil)
      @_context  = _context
      @_parent   = _parent
      @_hash     = {}
      @_after_handler = nil
    end

    def after_crawl(&block)
      @_after_handler = block
    end

    #options[:as]     :collection, :resource
    #options[:match]  :first, :all
    #options[:syntax] :xpath, :css
    def method_missing(meth, *args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:syntax]  ||= :css
      options[:match]   ||= :first
      options[:attr]    ||= nil
      selector          = args.shift

      if options[:as] == :collection
        @_hash[meth] = []
        result = _context.all( options[:syntax], selector )      
        result.each do |ele|
          @_hash[meth].push Structure.build(ele, self, &block)
        end 
      elsif options[:as] == :resource
        result = _context.first( options[:syntax], selector )
        @_hash[meth] = Structure.build(result, self, &block)
      elsif block
        if selector
          result = _context.send( options[:match], options[:syntax], selector )
        else
          result = _context
        end

        if options[:match] == :all
          @_hash[meth] = []
          result.each do |node|
            @_hash[meth] << block.call( node )
          end
        else
          @_hash[meth] = block.call( result )
        end
      else
        result = _context.send( options[:match], options[:syntax], selector )
        if options[:match] == :all
          @_hash[meth] = []
          result.each do |node|
            @_hash[meth] << (node[options[:attr]] || node.try(:text))
          end        
        else
          @_hash[meth] = (result[options[:attr]] || result.try(:text))
        end
      end
    end
  end
end