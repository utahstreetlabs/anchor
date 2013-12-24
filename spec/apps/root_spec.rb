require 'spec_helper'
require 'rack/test'
require 'anchor/apps/root'

describe Anchor::RootApp do
  include Rack::Test::Methods

  def app
    Anchor::RootApp
  end

  context "GET /" do
    it "shows name and version" do
      get '/'
      last_response.body.should =~ /Anchor v#{Anchor::VERSION}/
    end
  end

  context "DELETE /" do
    it 'should delete all data' do
      3.times { FactoryGirl.create(:listing) }
      delete '/'
      last_response.status.should == 204
      Listing.count.should == 0
    end
  end
end
