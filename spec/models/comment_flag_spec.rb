require 'spec_helper'
require 'anchor/models/comment'
require 'anchor/models/comment_flag'

describe CommentFlag do
  it "validates that user id is present" do
    flag = CommentFlag.new
    flag.should_not be_valid
    flag.errors[:user_id].first.should =~ %r{blank}
  end

  it "validates that user id is unique within the scope of a comment" do
    existing = FactoryGirl.create(:comment_flag)
    flag = existing.comment.flags.create(user_id: existing.user_id)
    flag.should_not be_valid
    flag.errors[:user_id].first.should =~ %r{taken}
  end

  it "validates that reason is present" do
    flag = CommentFlag.new
    flag.should_not be_valid
    flag.errors[:reason].first.should =~ %r{blank}
  end

  it "validates that reason is not too long" do
    flag = CommentFlag.new(reason: 'tortoise'*100)
    flag.should_not be_valid
    flag.errors[:reason].first.should =~ %r{too long}
  end

  it "validates that description does not have to be present" do
    flag = CommentFlag.new
    flag.errors[:description].should be_empty
  end

  it "validates that description is not too long" do
    flag = CommentFlag.new(description: 'tortoise'*100)
    flag.should_not be_valid
    flag.errors[:description].first.should =~ %r{too long}
  end
end
