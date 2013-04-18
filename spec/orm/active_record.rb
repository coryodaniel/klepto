# encoding: utf-8
require 'active_record'

ActiveRecord::Base.logger = ActiveSupport::BufferedLogger.new('log/test.log')
ActiveRecord::Base.establish_connection YAML.load(File.open(File.join(File.dirname(__FILE__), 'database.yml')).read)[ENV['db'] || 'mysql']

ActiveRecord::Migration.verbose = false

class TestMigration < ActiveRecord::Migration
  def self.up
    create_table :tweets, :force => true do |t|
      t.string :tweet
      t.string :twitter_id
      t.integer :timestamp
      t.string :permalink
    end

    create_table :users, :force => true do |t|
      t.string :name
      t.string :username
    end
  end

  def self.down
    drop_table :tweets
    drop_table :users
  end
end

class Tweet < ActiveRecord::Base
  validates_presence_of :timestamp, :twitter_id, :permalink, :tweet
end

class User < ActiveRecord::Base
  validates_presence_of :username, :name
end