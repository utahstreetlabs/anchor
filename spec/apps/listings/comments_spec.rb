require 'spec_helper'
require 'rack/test'
require 'anchor/apps/listings/comments'

describe Anchor::ListingCommentsApp do
  include Rack::Test::Methods

  def app
    Anchor::ListingCommentsApp
  end

  describe 'getting comment information' do
    let!(:listing)  { FactoryGirl.create(:listing) }
    let!(:comments) { 1.upto(3).map {|num| FactoryGirl.create(:comment, listing: listing)} }

    it "gets all of a listing's comments" do
      get "/listings/#{listing.listing_id}/comments"
      last_response.status.should == 200
      last_response.json[:comments].map {|c| c['_id']}.should == comments.map {|c| c.id.to_s}
    end

    it "gets a count of the listing's comments" do
      get "/listings/#{listing.listing_id}/comments/count"
      last_response.status.should == 200
      last_response.json[:count].should == 3
    end
  end

  it "autocreates a nonexisting listing when getting its comments" do
    listing_id = 12345
    get "/listings/#{listing_id}/comments"
    last_response.status.should == 200
    last_response.json[:comments].should have(:no).comments
    Listing.all.should have(1).comments
  end

  context "POST /listings/:listing_id/comments" do
    it "returns 400 when an entity is not provided" do
      post "/listings/123/comments"
      last_response.status.should == 400
    end

    context "when the listing does not exist" do
      let(:user_id) { 7890 }
      let(:listing_id) { 12345 }
      let(:attrs) { {user_id: user_id, text: 'used to be one of the rotten ones'} }

      before { post "/listings/#{listing_id}/comments", Yajl::Encoder.encode(attrs) }

      it "returns 201" do
        last_response.status.should == 201
      end

      it "returns the comment" do
        last_response.json[:user_id].should == user_id
      end

      it "creates the listing" do
        Listing.count.should == 1
      end
    end

    context "when the listing exists" do
      let(:user_id) { 7890 }
      let(:listing) { FactoryGirl.create(:listing) }
      let(:attrs) { {user_id: user_id, text: 'used to be one of the rotten ones'} }

      before { post "/listings/#{listing.listing_id}/comments", Yajl::Encoder.encode(attrs) }

      it "returns 201" do
        last_response.status.should == 201
      end

      it "returns the comment" do
        last_response.json[:user_id].should == user_id
      end
    end
  end

  context "DELETE /listings/:listing_id/comments" do
    it "returns 404 when the listing does not exist" do
      delete "/listings/123/comments"
      last_response.status.should == 404
    end

    context "when the listing exists" do
      let(:comment_count) { 3 }
      let(:listing) do
        listing = FactoryGirl.create(:listing)
        1.upto(comment_count) { FactoryGirl.create(:comment, listing: listing) }
        listing
      end

      before { delete "/listings/#{listing.listing_id}/comments" }

      it "returns 204" do
        last_response.status.should == 204
      end

      it "deletes the comments" do
        Listing.where(listing_id: listing.listing_id).first.comments.should have(:no).comments
      end
    end
  end

  context "GET /listings/many/:listing_ids/comments/summaries" do
    it "returns a comment summary for each listing" do
      l1 = FactoryGirl.create(:listing)
      c1 = FactoryGirl.create(:comment, listing: l1, text: "foo")
      l2 = FactoryGirl.create(:listing)
      get "/listings/many/#{l1.listing_id};#{l2.listing_id}/comments/summaries", user_id: c1.user_id
      last_response.status.should == 200
      data = last_response.json
      data.should have(2).entries
      data[l1.listing_id.to_s.to_sym].should == {'total' => 1, 'user_id' => c1.user_id,
        'commented' => true, 'comments' => { c1.id.to_s => { 'user_id' => c1.user_id, 'created_at' => c1.created_at.to_i,
            'listing_id' => l1.id.to_s, 'text' => "foo" } } }
      data[l2.listing_id.to_s.to_sym].should == {'total' => 0, 'user_id' => c1.user_id,
        'commented' => false, 'comments' => {} }
    end
  end
end
