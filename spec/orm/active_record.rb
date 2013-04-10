# encoding: utf-8
require 'active_record'

ActiveRecord::Base.logger = ActiveSupport::BufferedLogger.new('log/test.log')
ActiveRecord::Base.establish_connection YAML.load(File.open(File.join(File.dirname(__FILE__), 'database.yml')).read)[ENV['db'] || 'mysql']

ActiveRecord::Migration.verbose = false

class TestMigration < ActiveRecord::Migration
  def self.up
    create_table :stores, :force => true do |t|
      t.string :name
      t.integer :savings
    end

    create_table :coupons, :force => true do |t|
      t.string :remote_id
      t.string :title
      t.string :url
      t.string :description
    end 
  end

  def self.down
    drop_table :coupons
    drop_table :stores
  end
end

class Coupon < ActiveRecord::Base
end
class Store < ActiveRecord::Base
end