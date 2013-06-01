module Klepto
  class Browser
    include Capybara::DSL

    attr_reader :url_to_structure
    def initialize(*args)
      Klepto.logger.debug("===== Initializing new browser. =====")
      super
    end

    # def set_driver(use_driver)
    #   @use_driver = use_driver
    # end

    # def use_driver
    #   @use_driver || :poltergeist
    # end

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
    
    # Capybara automatically follows redirects... Checking the page here
    # to see if it has changed, and if so add it on to the stack of statuses.
    # statuses is an array because it holds the actually HTTP response code and an
    # approximate code (2xx for example). :redirect will be pushed onto the stack if a
    # redirect happened.    
    def statuses
      if !was_redirected?
        [status, statusx]
      else
        [status, statusx, :redirect]
      end
    end

    def statusx
      page.status_code.to_s[0..-3] + "xx"
    end
    
    def fetch!(_url)
      @url_to_structure = _url
      Klepto.logger.debug("Fetching #{@url_to_structure}")

      #Capybara.using_driver use_driver do
        visit @url_to_structure
        page
      #end
    end
  end
end
