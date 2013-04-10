require 'spec_helper'
require 'open-uri'

describe Klepto::Crawler, :vcr => {:record => :new_episodes} do
  describe 'dsl interaction' do
    before(:each) do
      @page = page("http://www.iana.org")
      @crawler = Klepto::Crawler.new('body',{:syntax => :css}) do
        scrape 'h1', :title

        scrape '#intro p' do |node|
          {description: node.text}
        end

        scrape_all '.home-panel h2' do |nodes|
          { sections: nodes.map{|n| n.text} }
        end
      end
      @resources = @crawler.crawl @page
    end #end before

    it 'should crawl the resource' do
      @resources.should have(1).resource
      @resources.first[:title].should match('Internet Assigned Numbers Authority')
      @resources.first[:description].should match(/^The Internet Assigned Numbers Authority/i)
      @resources.first[:sections].should have(3).sections
    end
  end

  describe 'standard interaction' do
    before(:each) do
      @page     = page()
      @crawler  = Klepto::Crawler.new 'body', {:syntax => :css}
    end
    it 'should have a CSS scope' do
      @crawler.scope.should eq 'body'
    end
    it 'should have a desired syntax' do
      @crawler.syntax.should == :css
    end    

    it 'should be able to scrape the node that the crawler is scoped to' do
      @crawler.scrape do |node|
        {:name => node.native.name}
      end
      resources = @crawler.crawl( @page )
      resources.should have(1).resource     
      resources.first[:name].should eq('body')
    end

    it 'should be able to designate scraping of a single node with a symbol' do
      @crawler.scrape 'h1', :title
      resources = @crawler.crawl( @page )
      resources.should have(1).resource     
      resources.first[:title].should eq('Example Domain')
    end

    it 'should be able to designate scraping of a single node with a block' do
      @crawler.scrape 'h1' do |node|
        {title: node.text}
      end

      resources = @crawler.crawl( @page )
      resources.should have(1).resource
      resources.first[:title].should eq('Example Domain')
    end

    it 'should be able to designate scraping of a set of nodes' do
      @crawler.scrape_all 'p' do |nodes|
        {
          paragraphs: [
            nodes.first.text, 
            nodes.last.text
          ]
        }
      end
      resources = @crawler.crawl( @page )
      resources.should have(1).resource
      resources.first[:paragraphs].should be_kind_of(Array)
      resources.first[:paragraphs].last.should eq("More information...")
    end    

    pending 'should be able to save a set of resources'
    pending 'should be able to specify a limit'
    pending 'should be able to specify a skip'
  end

end