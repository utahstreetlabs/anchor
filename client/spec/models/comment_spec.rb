require 'spec_helper'
require 'anchor/models/comment'

describe Anchor::Comment do
  [:listing_id, :user_id].each do |fk|
    it "validates #{fk} is present" do
      comment = Anchor::Comment.new
      comment.should_not be_valid
      comment.errors[fk].first.should =~ %r{can't be blank}
    end

    it "validates #{fk} is an integer" do
      comment = Anchor::Comment.new(fk => 45.67)
      comment.should_not be_valid
      comment.errors[fk].first.should =~ %r{must be an integer}
    end
  end

  it "validates text is present" do
    comment = Anchor::Comment.new
    comment.should_not be_valid
    comment.errors[:text].first.should =~ %r{can't be blank}
  end

  it "validates text is not too long" do
    comment = Anchor::Comment.new(text: 'oof'*500)
    comment.should_not be_valid
    comment.errors[:text].first.should =~ %r{is too long}
  end

  it "creates a valid comment" do
    listing_id = 1
    user_id = 2
    text = 'that slow dog is hit again'
    entity = {'listing_id' => listing_id, 'user_id' => user_id, 'text' => text, '_id' => 'deadbeef'}
    Anchor::Listings.expects(:fire_post).with(Anchor::Listings.listing_comments_url(listing_id), is_a(Hash)).
      returns(entity)
    comment = Anchor::Comment.create(listing_id: listing_id, user_id: user_id, text: text)
    comment.should be_a(Anchor::Comment)
    comment.listing_id.should == listing_id
  end

  it "does not create an invalid comment" do
    Anchor::Listings.expects(:fire_post).never
    comment = Anchor::Comment.create({})
    comment.should be_a(Anchor::Comment)
  end

  it "handles service failure when creating a comment" do
    Anchor::Listings.expects(:fire_post).returns(nil)
    comment = Anchor::Comment.create(listing_id: 1, user_id: 2, text: 'Hey Gepetto')
    comment.should be_nil
  end

  it "finds an existing comment" do
    listing_id = 1
    attrs = {'_id' => 'deadbeef'}
    Anchor::Comments.expects(:fire_get).with(Anchor::Comments.comment_url(attrs['_id'])).returns(attrs)
    comment = Anchor::Comment.find(listing_id, attrs['_id'])
    comment.should be_a(Anchor::Comment)
    comment.listing_id.should == listing_id
  end

  it "does not find a nonexistent comment" do
    listing_id = 1
    comment_id = 'deadbeef'
    Anchor::Comments.expects(:fire_get).with(Anchor::Comments.comment_url(comment_id)).returns(nil)
    comment = Anchor::Comment.find(listing_id, comment_id)
    comment.should be_nil
  end

  it "destroys a comment" do
    comment = Anchor::Comment.new(id: 'deadbeef')
    Anchor::Comments.expects(:fire_delete).with(Anchor::Comments.comment_url(comment.id))
    comment.destroy
  end

  it "destroys a comment (class)" do
    listing_id = 1
    comment_id = 'deadbeef'
    Anchor::Comments.expects(:fire_delete).with(Anchor::Comments.comment_url(comment_id))
    Anchor::Comment.destroy(listing_id, comment_id)
  end

  it "creates a flag" do
    attrs = {'_id' => 'cafebebe', 'reason' => 'spam', 'user_id' => 123}
    comment = Anchor::Comment.new(id: 'deadbeef')
    Anchor::CommentFlags.expects(:fire_put).
      with(Anchor::CommentFlags.comment_flags_user_url(comment.id, attrs['user_id']), is_a(Hash)).
      returns(attrs)
    flag = comment.create_flag(reason: attrs['reason'], user_id: attrs['user_id'])
    flag.should be_a(Anchor::CommentFlag)
    comment.flags.should == [flag]
  end

  it "unflags a comment" do
    comment = Anchor::Comment.new(id: 'deadbeef', flags: [{'_id' => 'cafebebe'}])
    Anchor::CommentFlag.expects(:delete_all).with(comment.id)
    comment.unflag
    comment.flags.should have(:no).flags
  end

  it "creates a reply" do
    attrs = {'_id' => 'cafebebe', 'user_id' => 123, 'text' => 'Yeah dogg!'}
    comment = Anchor::Comment.new(id: 'deadbeef')
    Anchor::CommentReplies.expects(:fire_post).
      with(Anchor::CommentReplies.comment_replies_url(comment.id), is_a(Hash)).
      returns(attrs)
    reply = comment.create_reply(user_id: attrs['user_id'], text: attrs['text'])
    reply.should be_a(Anchor::CommentReply)
    reply.parent_id.should == comment.id
    comment.replies.should == [reply]
  end

  it "deletes a reply" do
    comment = Anchor::Comment.new(id: 'deadbeef', 'child_comments' => [{id: 'cafebebe'}])
    reply = comment.replies.first
    comment.replies.should have(1).reply
    reply.expects(:destroy)
    comment.delete_reply(reply)
    comment.replies.should have(:no).replies
  end

  it "deletes a reply by id" do
    comment = Anchor::Comment.new(id: 'deadbeef', 'child_comments' => [{id: 'cafebebe'}])
    reply = comment.replies.first
    comment.replies.should have(1).reply
    Anchor::CommentReply.expects(:destroy).with(comment.id, reply.id)
    comment.delete_reply(reply.id)
    comment.replies.should have(:no).replies
  end
end
