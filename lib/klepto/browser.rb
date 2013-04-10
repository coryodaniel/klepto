module Klepto
  class Browser
    include Capybara::DSL

    def initialize(*args)
      super
    end

    def set_headers(headers)
      page.driver.headers = headers
    end
    
    def fetch!(url)
      visit url
      page
    end
  end
end
