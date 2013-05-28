module Klepto
  class Structure
   def self.build(_context=nil, _parent=nil, &block)
      structure = Structure.new(_context, _parent)
      structure.instance_eval &block
      structure._hash
    end

    attr_reader :_parent
    attr_reader :_hash
    attr_reader :_context

    def initialize(_context=nil, _parent=nil)
      @_context  = _context
      @_parent   = _parent
      @_hash     = {}
      @_after_handler = nil
    end

    #options[:as]     :collection, :resource
    #options[:match]  :first, :all
    #options[:syntax] :xpath, :css
    #options[:limit]  Integer elements to structure when :match => :all or :as => :collection
    def method_missing(meth, *args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:syntax]  ||= :css
      options[:match]   ||= :first
      options[:attr]    ||= nil
      options[:default] ||= nil
      options[:limit]   ||= nil
      selector          = args.shift

      if options[:as] == :collection
        
        @_hash[meth] = []
        result = _context.all( options[:syntax], selector )      
        options[:limit] ||= result.length
        result[0, options[:limit]].each do |ele|
          @_hash[meth].push Structure.build(ele, self, &block)
        end 

      elsif options[:as] == :resource
        
        result = _context.first( options[:syntax], selector )
        @_hash[meth] = Structure.build(result, self, &block)
      
      elsif block
      
        result = selector ? 
          _context.send( options[:match], options[:syntax], selector ) : _context

        if options[:match] == :all

          @_hash[meth] = []
          options[:limit] ||= result.length
          result[0, options[:limit]].each do |node|
            @_hash[meth] << block.call( node )
          end

        else
          if result
            @_hash[meth] = block.call( result )
          else
            @_hash[meth] = options[:default]
          end
        end

      else
        result = _context.send( options[:match], options[:syntax], selector )

        if options[:match] == :all
          @_hash[meth] = []
          options[:limit] ||= result.length
          result[0, options[:limit]].each do |node|
            @_hash[meth] << (node[options[:attr]] || node.try(:text))
          end        
        elsif result
          @_hash[meth] = (result[options[:attr]] || result.try(:text))
        else
          @_hash[meth] = options[:default]
        end
      end
    end
  end
end