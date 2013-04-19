module Klepto
  class Browser
    include Capybara::DSL

    def initialize(*args)
      super
    end

    def set_headers(headers)
      page.driver.headers = headers
    end

    def status
      page.status_code
    end

    def success?
      page.status_code == 200
    end
    
    def failure?
      !success?
    end

    def statusx
      page.status_code.to_s[0..-3] + "xx"
    end
    
    def fetch!(url)
      visit url
      page
    end
  end
end
