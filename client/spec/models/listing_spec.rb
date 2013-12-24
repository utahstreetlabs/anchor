require 'spec_helper'
require 'anchor/models/listing'

describe Anchor::Listing do
  context "a listing" do
    subject { Anchor::Listing.new(listing_id: 23) }
    let(:user_id) { 42 }

    it "creates a comment" do
      text = 'Nicki Minaj is the shit'
      comment = stub('comment')
      Anchor::Comment.expects(:create).with(has_entries(listing_id: subject.listing_id, user_id: user_id, text: text)).
        returns(comment)
      subject.comment(user_id, text: text).should == comment
    end

    it "fails to create a comment" do
      text = 'Lil Wayne is kinda boring'
      Anchor::Comment.expects(:create).with(has_entries(listing_id: subject.listing_id, user_id: user_id, text: text)).
        returns(nil)
      subject.comment(user_id, text: text).should be_nil
    end

    it "returns its comments" do
      comments = 1.upto(4).map {|id| {id: id}}
      url = Anchor::Listings.listing_comments_url(subject.listing_id)
      Anchor::Listings.expects(:fire_get).with(url, is_a(Hash)).returns({'comments' => comments})
      subject.comments.should have(comments.count).comments
    end

    it "returns its comment count" do
      count = 4
      url = Anchor::Listings.listing_comments_count_url(subject.listing_id)
      Anchor::Listings.expects(:fire_get).with(url, is_a(Hash)).returns({'count' => count})
      subject.comments_count.should == count
    end

    it "increments its view count" do
      attrs = {"_id" => 'deadbeef', 'listing_id' => 123, 'views' => 10}
      Anchor::Listings.expects(:fire_post).
        with(Anchor::Listings.listing_views_url(subject.listing_id), is_a(Hash)).
        returns(attrs)
      updated = subject.incr_views
      updated.should be_a(Anchor::Listing)
      updated.should_not == subject
      updated.views.should == attrs['views']
    end

    it "fails to increment its view count" do
      Anchor::Listings.expects(:fire_post).
        with(Anchor::Listings.listing_views_url(subject.listing_id), is_a(Hash)).
        returns(nil)
      updated = subject.incr_views
      updated.should == subject
    end

    it "increments its share count" do
      network = 'twitter'
      attrs = {"_id" => 'deadbeef', 'listing_id' => 123, 'shares' => {'twitter' => 10}}
      Anchor::Listings.expects(:fire_post).
        with(Anchor::Listings.listing_shares_url(subject.listing_id, network), is_a(Hash)).
        returns(attrs)
      updated = subject.incr_shares(network)
      updated.should be_a(Anchor::Listing)
      updated.should_not == subject
      updated.shares.should == attrs['shares']
    end

    it "fails to increment its share count" do
      network = 'etsy'
      Anchor::Listings.expects(:fire_post).
        with(Anchor::Listings.listing_shares_url(subject.listing_id, network), is_a(Hash)).
        returns(nil)
      updated = subject.incr_shares(network)
      updated.should == subject
    end

    it 'updates attributes' do
      subject.state = 'active'
      url = Anchor::Listings.listing_url(subject.listing_id)
      patch = [{add: '/state', value: subject.state}]
      attrs = {"_id" => 'deadbeef', 'listing_id' => subject.listing_id, 'state' => subject.state}
      Anchor::Listings.expects(:fire_patch).with(url, patch).returns(attrs)
      updated = subject.update
      updated.should be_a(Anchor::Listing)
      updated.should_not == subject
      updated.state.should == subject.state
    end

    it "finds an existing listing" do
      attrs = {'listing_id' => 123}
      Anchor::Listings.expects(:fire_get).with(Anchor::Listings.listing_url(attrs['listing_id'])).returns(attrs)
      listing = Anchor::Listing.find(attrs['listing_id'])
      listing.should be_a(Anchor::Listing)
      listing.listing_id.should == attrs['listing_id']
    end

    it "does not find a nonexistent listing" do
      listing_id = 123
      Anchor::Listings.expects(:fire_get).with(Anchor::Listings.listing_url(listing_id)).returns(nil)
      listing = Anchor::Listing.find(listing_id)
      listing.should be_nil
    end

    it "destroys a listing" do
      listing = Anchor::Listing.new(listing_id: 123)
      Anchor::Listings.expects(:fire_delete).with(Anchor::Listings.listing_url(listing.listing_id))
      listing.destroy
    end

    it "destroys a listing (class)" do
      listing_id = 123
      Anchor::Listings.expects(:fire_delete).with(Anchor::Listings.listing_url(listing_id))
      Anchor::Listing.destroy(listing_id)
    end
  end

  it "returns stats for multiple listings" do
    listing_ids = [23, 24, 25]
    stats = {23 => {}, 24 => {}, 25 => {}}
    user_id = 1
    url = Anchor::Listings.stats_for_listings_url
    Anchor::Listings.expects(:fire_get).with(url, is_a(Hash)).once.returns({'stats' => stats})
    Anchor::Listing.stats(listing_ids, user_id: user_id).should have(stats.count).stats
  end

  it "returns comment summaries for multiple listings" do
    listing_ids = [23, 24, 25]
    user_id = 1
    data = {
      23 => {total: 0, user_id: user_id, commented: false},
      24 => {total: 3, user_id: user_id, commented: true},
      25 => {total: 6, user_id: user_id, commented: false}
    }
    url = Anchor::Listings.listings_comment_summaries_url(listing_ids)
    Anchor::Listings.expects(:fire_get).with(url, has_entry(user_id: user_id)).returns(data)
    summaries = Anchor::Listing.comment_summaries(listing_ids, user_id: user_id)
    summaries.should have(listing_ids.count).entries
    data.each_pair do |id, val|
      summary = summaries[id]
      summary.total.should == val[:total]
      summary.user_id.should == val[:user_id]
      summary.commented.should == val[:commented]
    end
  end
end
