require 'spec_helper'
require 'rack/test'
require 'anchor/apps/comments/replies'

describe Anchor::CommentRepliesApp do
  include Rack::Test::Methods

  def app
    Anchor::CommentRepliesApp
  end

  it "creates a reply" do
    comment = FactoryGirl.create(:comment)
    attrs = {user_id: 123, text: 'QFT!'}
    post "/comments/#{comment.id}/replies", Yajl::Encoder.encode(attrs)
    last_response.status.should == 201
    last_response.json[:user_id].should == attrs[:user_id]
    last_response.json[:text].should == attrs[:text]
    comment.listing.reload
    comment.listing.comments.where(_id: comment.id).first.child_comments.should have(1).reply
  end

  it "returns 400 when creating a reply without an entity" do
    comment = FactoryGirl.create(:comment)
    post "/comments/#{comment.id}/replies", Yajl::Encoder.encode({})
    last_response.status.should == 400
  end

  it "returns 404 when creating a reply for a comment that does not exist" do
    post "/comments/#{BSON::ObjectId.new}/replies", Yajl::Encoder.encode({})
    last_response.status.should == 404
  end

  it "deletes all of a comment's replies" do
    comment = FactoryGirl.create(:comment)
    reply = FactoryGirl.create(:reply, parent_comment: comment)
    comment.listing.comments.where(_id: comment.id).first.replies.should have(1).reply
    delete "/comments/#{comment.id}/replies"
    last_response.status.should == 204
    comment.listing.reload
    comment.listing.comments.where(_id: comment.id).first.replies.should have(:no).replies
  end

  it "returns 404 when deleting replies for a comment that doesn't exist" do
    delete "/comments/#{BSON::ObjectId.new}/replies"
    last_response.status.should == 404
  end

  it "gets a reply" do
    comment = FactoryGirl.create(:comment)
    reply = FactoryGirl.create(:reply, parent_comment: comment)
    get "/comments/#{comment.id}/replies/#{reply.id}"
    last_response.status.should == 200
    last_response.json[:_id].should == reply.id.to_s
  end

  it "returns 404 when getting a reply for a comment that does not exist" do
    get "/comments/#{BSON::ObjectId.new}/replies/cafebebe"
    last_response.status.should == 404
  end

  it "deletes a reply" do
    comment = FactoryGirl.create(:comment)
    reply1 = FactoryGirl.create(:reply, parent_comment: comment)
    reply2 = FactoryGirl.create(:reply, parent_comment: comment)
    comment.listing.comments.where(_id: comment.id).first.replies.should have(2).replies
    delete "/comments/#{comment.id}/replies/#{reply1.id}"
    last_response.status.should == 204
    comment.listing.reload
    comment.listing.comments.where(_id: comment.id).first.replies.should have(1).reply
  end

  it "returns 404 when deleting a reply for a comment that doesn't exist" do
    delete "/comments/#{BSON::ObjectId.new}/replies/cafebebe"
    last_response.status.should == 404
  end
end
