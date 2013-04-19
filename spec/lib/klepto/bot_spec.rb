require 'spec_helper'

describe Klepto::Bot do  
  describe 'Klepto::Bot.new' do
    describe 'create a bot with a redirect' do
      before(:each) do
        @bot = Klepto::Bot.new("https://www.twitter.com/justinbieber"){
          name      'h1.fullname'
          config.on_http_status(:redirect){
            StatusLog.create message: 'redirect'
          }
          config.on_http_status(200){
            StatusLog.create message: '200'
          }            
        }      
        @structure = @bot.resources
      end

      it 'should structure the data' do
        @structure.first[:name].should match(/Justin/i)
      end      

      it 'should have dispatched status handlers' do
        statuses = StatusLog.all.map(&:message)
        statuses.should include 'redirect'
        statuses.should include '200'
      end
    end

    describe 'crawling multiple pages' do
      before(:each) do
        @bot = Klepto::Bot.new("https://twitter.com/justinbieber"){
          config.urls "https://twitter.com/ladygaga"
          name 'h1.fullname'
        }
        @structure = @bot.resources
      end

      it 'should have both pages data' do
        @structure.first[:name].should match(/Justin/i)
        @structure.last[:name].should match(/Lady/i)
      end
    end

    describe 'creating a bot' do
      before(:each) do
        @bot = Klepto::Bot.new("https://twitter.com/justinbieber"){
          config.headers({
            'Referer'     => 'http://www.twitter.com',
            'X-Sup-Dawg'  => "Yo, What's up?"
          })

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

          config.on_http_status('2xx'){
            StatusLog.create message: '2xx'
          }

          config.on_http_status(:redirect){
            StatusLog.create message: 'redirect'
          }

          config.on_http_status(200){
            StatusLog.create message: '200'
          }

          config.after(:each) do |resource|
            @user = User.new
            @user.name = resource[:name]
            @user.username = resource[:username]
            @user.save

            resource[:tweets].each do |tweet|
              Tweet.create(tweet)
            end
          end 
        }
        @structure = @bot.resources
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

      it 'should have dispatched status handlers' do
        statuses = StatusLog.all.map(&:message)

        statuses.should_not include 'redirect'
        statuses.should include '200'
        statuses.should include '2xx'
      end
    end
  end
end