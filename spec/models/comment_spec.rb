require 'spec_helper'
require 'anchor/models/comment'

describe Comment do
  it "validates that user id is present" do
    comment = Comment.new
    comment.should_not be_valid
    comment.errors[:user_id].first.should =~ %r{blank}
  end

  it "validates that text is present" do
    comment = Comment.new
    comment.should_not be_valid
    comment.errors[:text].first.should =~ %r{blank}
  end

  it "validates that text is not too long" do
    comment = Comment.new(text: 'tortoise'*100)
    comment.should_not be_valid
    comment.errors[:text].first.should =~ %r{too long}
  end
end
