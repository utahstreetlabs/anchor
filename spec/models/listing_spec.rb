require 'spec_helper'
require 'anchor/models/listing'

describe Listing do
  describe '.total_comments_and_replies' do
    subject { FactoryGirl.create(:listing) }

    it 'includes replies from each comment' do
      c1 = FactoryGirl.create(:comment, listing: subject)
      FactoryGirl.create_list(:reply, 3, parent_comment: c1)
      c2 = FactoryGirl.create(:comment, listing: subject)
      FactoryGirl.create_list(:reply, 2, parent_comment: c2)
      subject.total_comments_and_replies.should == 7
    end
  end

  describe '.comment_summaries' do
    subject { FactoryGirl.create(:listing) }

    it 'includes user ids and text from each comment' do
      c1 = FactoryGirl.create(:comment, listing: subject, user_id: 1, text: "foo")
      c1_replies = FactoryGirl.create_list(:reply, 3, parent_comment: c1, user_id: 3, text: "bar", created_at: c1.created_at)
      c2 = FactoryGirl.create(:comment, listing: subject, user_id: 2, text: "baz")
      c2_replies = FactoryGirl.create_list(:reply, 2, parent_comment: c2, user_id: 3, text: "quux", created_at: c2.created_at)
      summaries = subject.comment_summaries
      summaries[c1.id].should == {user_id: 1, text: "foo", listing_id: subject.id.to_s, created_at: c1.created_at.to_i}
      summaries[c2.id].should == {user_id: 2, text: "baz", listing_id: subject.id.to_s, created_at: c2.created_at.to_i}
      c1_replies.each { |r| summaries[r.id].should == {user_id: 3, text: "bar", listing_id: subject.id.to_s, created_at: c1.created_at.to_i } }
      c2_replies.each { |r| summaries[r.id].should == {user_id: 3, text: "quux", listing_id: subject.id.to_s, created_at: c2.created_at.to_i } }
    end
  end

  describe '.commented_on_by_user?' do
    subject { FactoryGirl.create(:listing) }

    context "when there are comments and replies" do
      before do
        c = FactoryGirl.create(:comment, listing: subject, user_id: 1)
        r = FactoryGirl.create(:reply, parent_comment: c, user_id: 2)
      end

      it 'returns true when the user made a comment' do
        subject.commented_on_by_user?(1).should be_true
      end

      it 'returns true when the user replied to a comment' do
        subject.commented_on_by_user?(2).should be_true
      end

      it 'returns false when the user did not make any of the comments or replies' do
        subject.commented_on_by_user?(3).should be_false
      end
    end

    context "when there are no comments or replies" do
      it 'returns false' do
        subject.commented_on_by_user?(1).should be_false
      end
    end
  end

  describe "#create" do
    context "without a listing_id" do
      subject { Listing.create }

      it "doesn't persist the listing" do
        subject.should_not be_persisted
      end

      it "adds an error on listing_id" do
        subject.errors[:listing_id].should have(1).error
        subject.errors[:listing_id].first.should =~ /blank/
      end
    end

    context "with a non-unique listing_id" do
      let(:existing) { FactoryGirl.create(:listing) }
      subject { Listing.create(listing_id: existing.listing_id) }

      it "doesn't persist the listing" do
        subject.should_not be_persisted
      end

      it "adds an error on listing_id" do
        subject.errors[:listing_id].should have(1).error
        subject.errors[:listing_id].first.should =~ /taken/
      end
    end
  end

  describe "#stats" do
    let(:views) { 10 }
    let(:shares) { {} }
    let(:listing) { Factory.create(:listing, views: views, shares: shares) }

    subject { listing.stats }

    its([:views]) { should == views }
    its([:shares]) { should == shares }
  end

  describe '#comment_summaries' do
    it 'returns a comment summary for each listing id' do
      user_id = 9
      l1 = Factory.create(:listing)
      l2 = Factory.create(:listing)
      c1 = Factory.create(:comment, listing: l1, user_id: user_id-1)
      r1 = Factory.create(:reply, parent_comment: c1, user_id: user_id)
      c2 = Factory.create(:comment, listing: l2, user_id: user_id+1)
      summaries = Listing.comment_summaries([l1.listing_id, l2.listing_id], user_id: user_id)
      summaries[l1.listing_id].should include(total: 2, commented: true, user_id: user_id)
      summaries[l2.listing_id].should include(total: 1, commented: false, user_id: user_id)
    end
  end

  context 'with user associations' do
    let(:user_id) { 123 }
    let(:other_user_id) { user_id + 1 }
    let(:comment_listing) { Factory.create(:listing) }
    let(:reply_listing) { Factory.create(:listing) }
    let(:flag_listing) { Factory.create(:listing) }
    let(:reply_flag_listing) { Factory.create(:listing) }
    let!(:no_relation_listing) { Factory.create(:listing) }

    before do
      c1 = Factory.create(:comment, listing: comment_listing, user_id: user_id)
      c2 = Factory.create(:comment, listing: reply_listing, user_id: other_user_id)
      Factory.create(:reply, parent_comment: c2, user_id: user_id)
      c3 = Factory.create(:comment, listing: flag_listing, user_id: other_user_id)
      Factory.create(:comment_flag, comment: c3, user_id: user_id)
      c4 = Factory.create(:comment, listing: reply_flag_listing, user_id: other_user_id)
      reply = Factory.create(:reply, parent_comment: c4, user_id: other_user_id)
      Factory.create(:comment_flag, comment: reply, user_id: user_id)
    end

    describe '::with_user_association' do
      subject { Listing.with_user_association(user_id).map(&:_id) }

      it 'finds all associated listings' do
        expect(subject).to have(4).items
      end

      it 'finds listings with comments' do
        expect(subject).to include(comment_listing.id)
      end

      it 'finds listings with comment replies' do
        expect(subject).to include(reply_listing.id)
      end

      it 'finds listings with flags' do
        expect(subject).to include(flag_listing.id)
      end

      it 'finds listings with comment reply flags' do
        expect(subject).to include(reply_flag_listing.id)
      end

      it "doesn't find unassociated listings" do
        expect(subject).to_not include(no_relation_listing.id)
      end
    end

    describe '#delete_user_info' do
      it 'deletes comments' do
        comment_listing.delete_user_info(user_id)
        expect(Listing.with_user_association(user_id).map(&:_id)).to_not include(comment_listing.id)
      end

      it 'deletes replies' do
        reply_listing.delete_user_info(user_id)
        expect(Listing.with_user_association(user_id).map(&:_id)).to_not include(reply_listing.id)
      end

      it 'deletes flags' do
        flag_listing.delete_user_info(user_id)
        expect(Listing.with_user_association(user_id).map(&:_id)).to_not include(flag_listing.id)
      end

      it 'deletes reply flags' do
        reply_flag_listing.delete_user_info(user_id)
        expect(Listing.with_user_association(user_id).map(&:_id)).to_not include(reply_flag_listing.id)
      end
    end
  end
end
