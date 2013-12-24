FactoryGirl.define do
  factory :listing do
    sequence(:listing_id) {|n| n}
    state 'active'
  end

  factory :comment do
    listing
    sequence(:user_id) {|n| n}
    text {|n| "Comment #{n}"}
  end

  factory :reply, class: 'Comment' do
    association :parent_comment, factory: :comment
    sequence(:user_id) {|n| n}
    text {|n| "Reply #{n}"}
  end

  factory :comment_flag do
    comment
    sequence(:user_id) {|n| n}
    reason "spam"
  end
end
