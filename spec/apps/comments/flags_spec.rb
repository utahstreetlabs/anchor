require 'spec_helper'
require 'rack/test'
require 'anchor/apps/comments/flags'

describe Anchor::CommentFlagsApp do
  include Rack::Test::Methods

  def app
    Anchor::CommentFlagsApp
  end

  it "gets all of a comment's flags" do
    comment = FactoryGirl.create(:comment)
    flags = 1.upto(3).map {|num| FactoryGirl.create(:comment_flag, comment: comment)}
    get "/comments/#{comment.id}/flags"
    last_response.status.should == 200
    last_response.json[:flags].map {|h| h['_id']}.should == flags.map {|f| f.id.to_s}
  end

  it "returns 404 when getting flags for a comment that does not exist" do
    get "/comments/#{BSON::ObjectId.new}/flags"
    last_response.status.should == 404
  end

  it "gets a user's flag for a comment" do
    comment = FactoryGirl.create(:comment)
    flag = FactoryGirl.create(:comment_flag, comment: comment)
    get "/comments/#{comment.id}/flags/users/#{flag.user_id}"
    last_response.status.should == 200
    last_response.json[:_id].should == flag.id.to_s
  end

  it "returns 404 when getting a user's flag for a comment that does not exist" do
    get "/comments/#{BSON::ObjectId.new}/flags/users/123"
    last_response.status.should == 404
  end

  it "returns 404 when getting a comment flag for a user that does not exist" do
    comment = FactoryGirl.create(:comment)
    get "/comments/#{comment.id}/flags/users/123"
    last_response.status.should == 404
  end

  it "creates a comment flag" do
    comment = FactoryGirl.create(:comment)
    user_id = 123
    attrs = {reason: 'spam', description: 'spammy mcspam spam'}
    put "/comments/#{comment.id}/flags/users/#{user_id}", Yajl::Encoder.encode(attrs)
    last_response.status.should == 200
    last_response.json[:user_id].should == user_id
    comment.listing.reload
    comment.listing.comments.where(_id: comment.id).first.flags.should have(1).flag
  end

  it "it silently fails to create a comment flag when one already exists for a user" do
    comment = FactoryGirl.create(:comment)
    flag = FactoryGirl.create(:comment_flag, comment: comment)
    comment.listing.comments.where(_id: comment.id).first.flags.should have(1).flag
    attrs = {reason: 'spam', description: 'spammy mcspam spam'}
    put "/comments/#{comment.id}/flags/users/#{flag.user_id}", Yajl::Encoder.encode(attrs)
    last_response.status.should == 200
    last_response.json[:user_id].should == flag.user_id
    comment.listing.reload
    comment.listing.comments.where(_id: comment.id).first.flags.should have(1).flag
  end

  it "returns 400 when creating a flag without an entity" do
    comment = FactoryGirl.create(:comment)
    put "/comments/#{comment.id}/flags/users/123", Yajl::Encoder.encode({})
    last_response.status.should == 400
  end

  it "returns 404 when creating a flag for a comment that does not exist" do
    put "/comments/#{BSON::ObjectId.new}/flags/users/123", Yajl::Encoder.encode({})
    last_response.status.should == 404
  end

  it "deletes all of a comment's flags" do
    comment = FactoryGirl.create(:comment)
    flag = FactoryGirl.create(:comment_flag, comment: comment)
    comment.listing.comments.where(_id: comment.id).first.flags.should have(1).flag
    delete "/comments/#{comment.id}/flags"
    last_response.status.should == 204
    comment.listing.reload
    comment.listing.comments.where(_id: comment.id).first.flags.should have(:no).flags
  end

  it "returns 404 when deleting flags for a comment that doesn't exist" do
    delete "/comments/#{BSON::ObjectId.new}/flags"
    last_response.status.should == 404
  end

  it "deletes a user's comment flag" do
    comment = FactoryGirl.create(:comment)
    flag1 = FactoryGirl.create(:comment_flag, comment: comment)
    flag2 = FactoryGirl.create(:comment_flag, comment: comment)
    comment.listing.comments.where(_id: comment.id).first.flags.should have(2).flags
    delete "/comments/#{comment.id}/flags/users/#{flag1.user_id}"
    last_response.status.should == 204
    comment.listing.reload
    comment.listing.comments.where(_id: comment.id).first.flags.should have(1).flag
  end

  it "returns 404 when deleting a user's flag for a comment that doesn't exist" do
    delete "/comments/#{BSON::ObjectId.new}/flags/users/123"
    last_response.status.should == 404
  end
end
