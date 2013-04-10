require 'docile'
require 'open-uri'
require 'logger'
require "capybara"
require "capybara/dsl"
require 'capybara/poltergeist'
require 'pp'

Capybara.run_server = false

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    js_errors: false
  })
end
Capybara.current_driver = :poltergeist

module Klepto
  LOG = Logger.new(STDOUT)
  LOG.level = Logger::WARN
end

require 'klepto/version'
require 'klepto/crawler'
require 'klepto/browser'
require 'klepto/bot'