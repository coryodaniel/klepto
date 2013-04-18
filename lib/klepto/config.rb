module Klepto
  class Config
    def initialize
      @headers = {}
      @urls    = []
    end

    def headers(_headers=nil)
      @headers = _headers if _headers
      @headers
    end

    def url(*args)
      @urls += args
    end
    alias :urls :url    
  end
end