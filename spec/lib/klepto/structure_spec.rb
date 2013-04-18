require 'spec_helper'
require 'pp'

describe Klepto::Structure do
  describe 'Klepto::Structure.build' do
    before(:each) do
      @page = Capybara::Node::Simple.new(open("./samples/bieber.html").read)

      @structure = Klepto::Structure.build(@page){
        name      'h1.fullname'
        username "//span[contains(concat(' ',normalize-space(@class),' '),' screen-name ')]", :syntax => :xpath
        tweet_ids 'li.stream-item', :match => :all, :attr => 'data-item-id'
        links 'span.url a', :match => :all do |node|
          node[:href]
        end

        last_tweet 'li.stream-item', :as => :resource do
          twitter_id do |node|
            node['data-item-id']
          end
          content '.content p'
          timestamp '._timestamp', :attr => 'data-time'
          permalink '.time a', :attr => :href
        end      

        tweets    'li.stream-item', :as => :collection do
          twitter_id do |node|
            node['data-item-id']
          end
          tweet '.content p', :css
          timestamp '._timestamp', :attr => 'data-time'
          permalink '.time a', :css, :attr => :href
        end       
      }
    end

    it 'should structure the data' do
      @structure[:name].should match(/Justin/i)
      @structure[:links].should == ["http://www.youtube.com/justinbieber"]
      @structure[:username].should eq '@justinbieber'
      @structure[:last_tweet][:twitter_id].should == @structure[:tweets].first[:twitter_id]
    end
  end

  describe 'Klepto::Structure.crawl' do
    before(:each) do
      config = {
        :headers => {
          'Referer'     => 'http://www.twitter.com',
          'X-Sup-Dawg'  => "Yo, What's up?"
        }
      }
      @structure = Klepto::Structure.crawl("https://twitter.com/justinbieber", config){
        # Structure that stuff
        name      'h1.fullname'
        username "//span[contains(concat(' ',normalize-space(@class),' '),' screen-name ')]", :syntax => :xpath
        tweet_ids 'li.stream-item', :match => :all, :attr => 'data-item-id'
        links 'span.url a', :match => :all do |node|
          node[:href]
        end

        last_tweet 'li.stream-item', :as => :resource do
          twitter_id do |node|
            node['data-item-id']
          end
          content '.content p'
          timestamp '._timestamp', :attr => 'data-time'
          permalink '.time a', :attr => :href
        end      

        tweets    'li.stream-item', :as => :collection do
          twitter_id do |node|
            node['data-item-id']
          end
          tweet '.content p', :css
          timestamp '._timestamp', :attr => 'data-time'
          permalink '.time a', :css, :attr => :href
        end

        after_crawl do |resource|
          @user = User.new
          @user.name = resource[:name]
          @user.username = resource[:username]
          @user.save

          resource[:tweets].each do |tweet|
            Tweet.create(tweet)
          end
        end 
      }
    end

    it 'should structure the data' do
      @structure.first[:name].should match(/Justin/i)
      @structure.first[:links].should == ["http://www.youtube.com/justinbieber"]
      @structure.first[:username].should eq '@justinbieber'
      @structure.first[:last_tweet][:twitter_id].should == @structure.first[:tweets].first[:twitter_id]
    end

    it 'should store the data' do
      User.count.should be(1)
      Tweet.count.should_not be(0)
    end
  end
end