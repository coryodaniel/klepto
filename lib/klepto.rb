require 'open-uri'
require 'logger'
require "capybara"
require "capybara/dsl"
require 'capybara/poltergeist'

Capybara.run_server = false

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    js_errors: false
  })
end
Capybara.current_driver = :poltergeist

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