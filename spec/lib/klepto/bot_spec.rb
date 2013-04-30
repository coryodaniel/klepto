require 'spec_helper'

describe Klepto::Bot do  
  describe 'Klepto::Bot.new' do
    describe 'create a bot with a redirect' do
      describe 'that aborts on redirect' do
        before(:each) do
          @bot = Klepto::Bot.new("https://www.twitter.com/justinbieber"){
            name      'h1.fullname'
            config.abort_on_redirect true
            
            config.after(:abort){
              StatusLog.create message: 'Abort!'
            }            
          }      
          @structure = @bot.resources
        end

        it 'should structure not have structured the data' do
          @structure.should be_empty
        end      

        it 'should have dispatched abort handlers' do
          statuses = StatusLog.all.map(&:message)
          statuses.should include 'Abort!'
        end
      end

      describe 'that follows a redirect' do
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

    end

    describe 'aborting after a failure' do
      before(:each) do
        @bot = Klepto::Bot.new("https://github.com/coryodaniel/nonexistentproject"){
          name 'h1.fullname'
          config.abort_on_failure true
          config.after(:abort) do |page|
            StatusLog.create message: 'Aborted.'
          end
        }
        @structure = @bot.resources
      end      

      it 'should abort after a 4xx or 5xx' do
        StatusLog.first.message.should eq("Aborted.")
      end
    end

    describe 'structuring a 4xx or 5xx response' do
      before(:each) do
        @bot = Klepto::Bot.new("https://github.com/coryodaniel/nonexistentproject"){
          cat 'img#parallax_octocat', :attr => :alt
          config.abort_on_failure false
          config.after(:abort) do |page|
            StatusLog.create message: 'Aborted.'
          end
        }
        @structure = @bot.resources
      end      

      it 'should perform structuring' do
        @structure.first[:cat].should eq('Octobi Wan Catnobi')
      end

      it 'should not abort after a 4xx or 5xx' do
        StatusLog.first.should be(nil)
      end
    end

    describe 'structuring multiple pages' do
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

          config.after(:get) do |page|
            StatusLog.create message: 'got a page'
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
        User.first.name.should eq( @structure.first[:name] )
        User.count.should be(1)
        Tweet.count.should_not be(0)
      end

      it 'should not have the DSL once its been processed' do
        lambda{
          @bot.i_dont_exist
        }.should raise_error(NoMethodError)
        
      end

      it 'should have dispatched status handlers' do
        statuses = StatusLog.all.map(&:message)

        statuses.should_not include 'redirect'
        statuses.should include '200'
        statuses.should include '2xx'
        statuses.should include 'got a page'
      end
    end

    describe 'handling an exception within a block' do
      before(:each) do
        @bot = Klepto::Bot.new("https://twitter.com/justinbieber"){
          name      'h1.fullname'
          username  "span.screen-name"
          
          tweets    'li.stream-item', :as => :collection do
            twitter_id do |node|
              node['data-item-id']
            end
            tweet '.content p', :css
            permalink '.time a', :css, :attr => :href
            timestamp '._timestamp' do |node|
              raise Exception
            end
          end          
        }
        @structure = @bot.resources
      end

      it 'should set the value to nil when an exception is raised' do
        @structure.first[:name].should match(/Justin/i)
        @structure.first[:tweets].first.keys.should include(:timestamp)
        @structure.first[:tweets].first[:timestamp].should be(nil)
      end
    end

    describe 'a page missing a selector' do
      before(:each) do
        @bot = Klepto::Bot.new("https://twitter.com/justinbieber"){
          name      'h1.fullname'
          username  "span.screen-NOPE", default: "CHICKENS"
        }
        @structure = @bot.resources
      end

      it 'should have a sensible default for the structure' do
        @structure.first[:username].should eq('CHICKENS')
      end
    end

    describe 'creating a bot with a node limit' do
      before(:each) do
        @bot = Klepto::Bot.new("https://twitter.com/justinbieber"){
          config.headers({
            'Referer'     => 'http://www.twitter.com',
            'X-Sup-Dawg'  => "Yo, What's up?"
          })

          # Structure that stuff
          name      'h1.fullname'
          username  "span.screen-name"
          
          tweets    'li.stream-item', :as => :collection, :limit => 5 do
            twitter_id do |node|
              node['data-item-id']
            end
            tweet '.content p', :css
            timestamp '._timestamp', :attr => 'data-time'
            permalink '.time a', :css, :attr => :href
          end

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

      it 'should limit the nodes structured' do
        User.count.should be(1)
        Tweet.count.should be(5)
      end
    end


  end
end