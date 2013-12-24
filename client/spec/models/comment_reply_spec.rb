require 'spec_helper'
require 'anchor/models/comment_reply'

describe Anchor::CommentReply do
  it "validates parent id is present" do
    parent = Anchor::CommentReply.new
    parent.should_not be_valid
    parent.errors[:parent_id].first.should =~ %r{can't be blank}
  end

  it "validates user id is present" do
    parent = Anchor::CommentReply.new
    parent.should_not be_valid
    parent.errors[:user_id].first.should =~ %r{can't be blank}
  end

  it "validates user id is an integer" do
    parent = Anchor::CommentReply.new(user_id: 45.67)
    parent.should_not be_valid
    parent.errors[:user_id].first.should =~ %r{must be an integer}
  end

  it "validates text is present" do
    parent = Anchor::CommentReply.new
    parent.should_not be_valid
    parent.errors[:text].first.should =~ %r{can't be blank}
  end

  it "validates text is not too long" do
    parent = Anchor::CommentReply.new(text: 'oof'*500)
    parent.should_not be_valid
    parent.errors[:text].first.should =~ %r{is too long}
  end

  it "creates a valid reply" do
    attrs = {'parent_id' => 'deadbeef', 'user_id' => 2, 'text' => 'yeah dogg!', '_id' => 'cafebebe'}
    Anchor::CommentReplies.expects(:fire_post).
      with(Anchor::CommentReplies.comment_replies_url(attrs['parent_id']), is_a(Hash)).
      returns(attrs)
    parent = Anchor::CommentReply.create(parent_id: attrs['parent_id'], user_id: attrs['user_id'], text: attrs['text'])
    parent.should be_a(Anchor::CommentReply)
    parent.parent_id.should == attrs['parent_id']
  end

  it "does not create an invalid reply" do
    Anchor::CommentReplies.expects(:fire_post).never
    reply = Anchor::Comment.create({})
    reply.should be_a(Anchor::Comment)
  end

  it "handles service failure when creating a reply" do
    Anchor::CommentReplies.expects(:fire_post).returns(nil)
    reply = Anchor::CommentReply.create(parent_id: 1, user_id: 2, text: 'Hey Gepetto')
    reply.should be_nil
  end

  it "destroys a reply" do
    reply = Anchor::CommentReply.new(id: 'cafebebe', parent_id: 'deadbeef')
    Anchor::CommentReplies.expects(:fire_delete).
      with(Anchor::CommentReplies.comment_reply_url(reply.parent_id, reply.id))
    reply.destroy
  end

  it "destroys a reply (class)" do
    parent_id = 'deadbeef'
    reply_id = 'cafebebe'
    Anchor::CommentReplies.expects(:fire_delete).
      with(Anchor::CommentReplies.comment_reply_url(parent_id, reply_id))
    Anchor::CommentReply.destroy(parent_id, reply_id)
  end
end
