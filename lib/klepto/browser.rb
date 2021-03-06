module Klepto
  class Browser
    include Capybara::DSL

    attr_reader :url_to_structure
    def initialize(*args)
      Klepto.logger.debug("===== Initializing new browser. =====")
      super
    end

    def set_driver(using_driver)
      @use_driver = Capybara.current_driver = Capybara.javascript_driver = using_driver
    end

    def use_driver
      @use_driver || :poltergeist
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

    def was_redirected?
      @url_to_structure != page.current_url
    end

    def similar_url?
      @url_to_structure.downcase == page.current_url.downcase
    end
    
    # Capybara automatically follows redirects... Checking the page here
    # to see if it has changed, and if so add it on to the stack of statuses.
    # statuses is an array because it holds the actually HTTP response code and an
    # approximate code (2xx for example). :redirect will be pushed onto the stack if a
    # redirect happened.    
    def statuses
      [status, statusx]
    end

    def statusx
      page.status_code.to_s[0..-3] + "xx"
    end
    
    def fetch!(_url)
      @url_to_structure = _url
      Klepto.logger.debug("Fetching (#{@use_driver}) #{@url_to_structure}")

      visit @url_to_structure
      page
    end
  end
end
