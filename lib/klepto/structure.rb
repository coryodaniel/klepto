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
      Klepto.logger.debug("\tnew Structure (#{_parent}) -> (#{_context})")
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
      options[:parser]  ||= nil
      selector          = args.shift

      if !block_given? && options[:parser]
        block = options[:parser].new
      end

      Klepto.logger.debug("\t\tDefining attribute: #{meth} -> #{selector}")

      if options[:as] == :collection
        @_hash[meth] = []
        result = _context.all( options[:syntax], selector )      

        Klepto.logger.debug("\t\t\tAs: collection, Result? #{!result.nil?}")

        options[:limit] ||= result.length
        result[0, options[:limit]].each do |ele|
          @_hash[meth].push Structure.build(ele, self, &block)
        end 

      elsif options[:as] == :resource
        result = _context.first( options[:syntax], selector )
        Klepto.logger.debug("\t\t\tAs: resource, Result? #{!result.nil?}")        
        @_hash[meth] = Structure.build(result, self, &block)
      elsif block
        result = selector ? 
          _context.send( options[:match], options[:syntax], selector ) : _context

        if options[:match] == :all
          Klepto.logger.debug("\t\t\tAs: block (match all), Result? #{!result.nil?}")
          @_hash[meth] = []
          options[:limit] ||= result.length
          result[0, options[:limit]].each do |node|
            @_hash[meth] << block.call( node )
          end
        else
          if result
            Klepto.logger.debug("\t\t\tAs: block (match one)")
            @_hash[meth] = block.call( result )
          else
            Klepto.logger.debug("\t\t\tAs: block (no match, default: #{options[:default]})")
            @_hash[meth] = options[:default]
          end
        end

      else
        result = _context.send( options[:match], options[:syntax], selector )

        if options[:match] == :all
          Klepto.logger.debug("\t\t\tAs: simple (match all), Result? #{!result.nil?}")
          @_hash[meth] = []
          options[:limit] ||= result.length
          result[0, options[:limit]].each do |node|
            @_hash[meth] << (node[options[:attr]] || node.try(:text))
          end        
        elsif result
          Klepto.logger.debug("\t\t\tAs: block (match one)")
          @_hash[meth] = (result[options[:attr]] || result.try(:text))
        else
          Klepto.logger.debug("\t\t\tAs: block (no match, default: #{options[:default]})")
          @_hash[meth] = options[:default]
        end
      end
    end
  end
end