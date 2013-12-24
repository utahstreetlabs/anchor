require 'spec_helper'
require 'rack/test'
require 'anchor/apps/listings'

describe Anchor::ListingsApp do
  include Rack::Test::Methods

  def app
    Anchor::ListingsApp
  end

  it "gets stats for a listing" do
    listing = FactoryGirl.create(:listing)
    get "/listings/stats?id[]=#{listing.listing_id}"
    last_response.status.should == 200
    last_response.json[:stats].should include(listing.listing_id.to_s)
  end

  it "passes relevant options through to stats" do
    listing = stub('listing', listing_id: 10)
    app.any_instance.expects(:find_or_create_listings).returns([listing])
    listing.expects(:stats).with(has_entries(includes: ['views']))

    get "/listings/stats?id[]=#{listing.listing_id}&fields[]=views"
    last_response.status.should == 200
  end

  it "gets stats for a nonexistent listing" do
    listing_id = 123
    get "/listings/stats?id[]=#{listing_id}"
    last_response.status.should == 200
    last_response.json[:stats].should include(listing_id.to_s)
  end

  it "gets a listing" do
    listing = FactoryGirl.create(:listing)
    get "/listings/#{listing.listing_id}"
    last_response.status.should == 200
    last_response.json[:_id].should == listing.id.to_s
  end

  it "returns 404 when getting a listing that does not exist" do
    get "/listings/123"
    last_response.status.should == 404
  end

  context "PATCH /listings/:id" do
    it 'updates listing attributes' do
      listing = FactoryGirl.create(:listing, state: 'incomplete')
      entity = [{add: '/state', value: 'active'}]
      patch "/listings/#{listing.listing_id}", entity.to_json
      last_response.status.should == 200
      last_response.json[:state].should == 'active'
    end
  end

  it "deletes a listing" do
    listing = FactoryGirl.create(:listing)
    delete "/listings/#{listing.listing_id}"
    last_response.status.should == 204
    Listing.all.should have(:no).listings
  end

  it "silently fails when deleting a listing that doesn't exist" do
    delete "/listings/123"
    last_response.status.should == 204
  end

  it "increments a listing's view count" do
    listing = FactoryGirl.create(:listing)
    post "/listings/#{listing.listing_id}/views"
    last_response.status.should == 201
    listing.reload
    listing.views.should == 1
    last_response.json[:views].should == listing.views
  end

  it "returns 404 when incrementing the view count of a listing that does not exist" do
    post "/listings/123/view"
    last_response.status.should == 404
  end

  it "increments a listing's twitter share count for the first time" do
    network = 'twitter'
    listing = FactoryGirl.create(:listing)
    post "/listings/#{listing.listing_id}/shares/#{network}"
    last_response.status.should == 201
    listing.reload
    listing.shares[network].should == 1
    last_response.json[:shares][network].should == listing.shares[network]
  end

  it "increments a listing's twitter share count subsequent to the first time" do
    network = 'twitter'
    count = 10
    listing = FactoryGirl.create(:listing, shares: {network => count})
    post "/listings/#{listing.listing_id}/shares/#{network}"
    last_response.status.should == 201
    listing.reload
    listing.shares[network].should == count+1
    last_response.json[:shares][network].should == listing.shares[network]
  end

  it "returns 404 when incrementing the twitter share count count of a listing that does not exist" do
    post "/listings/123/shares/twitter"
    last_response.status.should == 404
  end
end
