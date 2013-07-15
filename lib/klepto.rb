require 'open-uri'
require 'logger'
require "capybara"
require "capybara/dsl"
require 'capybara/poltergeist'

# TODO: This causes issues, obviously when loaded in a test environment running capybara...
Capybara.run_server = false

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    js_errors: false
  })
end
Capybara.javascript_driver = Capybara.current_driver = :poltergeist

module Klepto
  def self.logger
    @@logger
  end
  def self.logger=(logger)
    @@logger = logger
  end
end
Klepto.logger       = Logger.new(STDOUT)
Klepto.logger.level = Logger::INFO
  
require 'klepto/version'
require 'klepto/config'
require 'klepto/browser'
require 'klepto/structure'
require 'klepto/bot'