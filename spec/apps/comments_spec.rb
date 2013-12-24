require 'spec_helper'
require 'rack/test'
require 'anchor/apps/comments'

describe Anchor::CommentsApp do
  include Rack::Test::Methods

  def app
    Anchor::CommentsApp
  end

  it "gets a comment" do
    comment = FactoryGirl.create(:comment)
    get "/comments/#{comment.id}"
    last_response.status.should == 200
    last_response.json[:_id].should == comment.id.to_s
  end

  it "gets a reply" do
    reply = FactoryGirl.create(:reply)
    get "/comments/#{reply.id}"
    last_response.status.should == 200
    last_response.json[:_id].should == reply.id.to_s
  end

  it "returns 404 when getting a comment that does not exist" do
    get "/comments/#{BSON::ObjectId.new}"
    last_response.status.should == 404
  end

  it "deletes a comment" do
    comment = FactoryGirl.create(:comment)
    comment.listing.should have(1).comment
    delete "/comments/#{comment.id}"
    last_response.status.should == 204
    comment.listing.reload
    comment.listing.should have(:no).comments
  end

  it "silently fails when deleting a comment that doesn't exist" do
    delete "/comments/#{BSON::ObjectId.new}"
    last_response.status.should == 204
  end
end
