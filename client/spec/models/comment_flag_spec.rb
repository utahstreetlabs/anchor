require 'spec_helper'
require 'anchor/models/comment'
require 'anchor/models/comment_flag'

describe Anchor::CommentFlag do
  it "validates user_id is present" do
    flag = Anchor::CommentFlag.new
    flag.should_not be_valid
    flag.errors[:user_id].first.should =~ %r{can't be blank}
  end

  it "validates user_id is an integer" do
    flag = Anchor::CommentFlag.new(:user_id => 45.67)
    flag.should_not be_valid
    flag.errors[:user_id].first.should =~ %r{must be an integer}
  end

  it "validates reason is present" do
    flag = Anchor::CommentFlag.new
    flag.should_not be_valid
    flag.errors[:reason].first.should =~ %r{can't be blank}
  end

  it "validates reason is not too long" do
    flag = Anchor::CommentFlag.new(reason: 'oof'*20)
    flag.should_not be_valid
    flag.errors[:reason].first.should =~ %r{is too long}
  end

  it "validates description does not have to be present" do
    flag = Anchor::CommentFlag.new
    flag.errors[:description].should be_empty
  end

  it "validates description is not too long" do
    flag = Anchor::CommentFlag.new(description: 'oof'*500)
    flag.should_not be_valid
    flag.errors[:description].first.should =~ %r{is too long}
  end

  it "creates a valid flag" do
    comment_id = 'cafebebe'
    user_id = 1
    reason = 'spam'
    description = 'Animal Collective is the worst garbage'
    entity = {'user_id' => user_id, 'reason' => reason, 'description' => description, '_id' => 'deadbeef'}
    Anchor::CommentFlags.expects(:fire_put).
      with(Anchor::CommentFlags.comment_flags_user_url(comment_id, user_id), is_a(Hash)).returns(entity)
    flag = Anchor::CommentFlag.create(comment_id, user_id: user_id, reason: reason, description: description)
    flag.should be_a(Anchor::CommentFlag)
  end

  it "does not create an invalid flag" do
    Anchor::CommentFlags.expects(:fire_put).never
    flag = Anchor::CommentFlag.create('cafebebe', {})
    flag.should be_a(Anchor::CommentFlag)
  end

  it "handles service failure when creating a flag" do
    Anchor::CommentFlags.expects(:fire_put).returns(nil)
    flag = Anchor::CommentFlag.create('cafebebe', user_id: 2, reason: 'ow', description: 'I hurt myself today')
    flag.should be_nil
  end

  it "deletes all flags" do
    comment_id = 'deadbeef'
    Anchor::CommentFlags.expects(:fire_delete).with(Anchor::CommentFlags.comment_flags_url(comment_id))
    Anchor::CommentFlag.delete_all(comment_id)
  end
end
