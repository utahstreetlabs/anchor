require 'ladon/model'
require 'anchor/models/comment'
require 'anchor/resource/listings'

module Anchor
  class Listing < Ladon::Model
    attr_accessor :listing_id, :views, :shares, :state

    def destroy
      Listings.fire_delete(Listings.listing_url(self.listing_id))
    end

    # Creates a comment on this listing by a user. Returns the new comment, or nil if an error occurred.
    def comment(user_id, attrs)
      Anchor::Comment.create(attrs.merge(listing_id: self.listing_id, user_id: user_id))
    end

    # Returns the listing's comments in reverse chronological order.
    def comments(options = {})
      data = Listings.fire_get(Listings.listing_comments_url(self.listing_id, options),
        default_data: {'comments' => []})
      data['comments'].map {|attrs| Anchor::Comment.new(attrs)}
    end

    # Returns a count of comments for this listing
    def comments_count
      Listings.fire_get(Listings.listing_comments_count_url(self.listing_id), default_data: {'count' => 0})['count']
    end

    # Increments the listing's view count and returns an updated +Listing+. If the update failed for some reason,
    # +self+ is returned instead.
    def incr_views
      attrs = Listings.fire_post(Listings.listing_views_url(self.listing_id), {})
      attrs ? self.class.new(attrs) : self
    end

    # Increments the listing's share count for +network+ and returns an updated +Listing+. If the update failed for some
    # reason, +self+ is returned instead.
    def incr_shares(network)
      attrs = Listings.fire_post(Listings.listing_shares_url(self.listing_id, network), {})
      attrs ? self.class.new(attrs) : self
    end

    # Updates the listing's attributes and returns an updated +Listing+. If the update failed for some reason, +self+
    # is returned instead.
    #
    # Note that the only supported attributes for update is +state+.
    def update
      patch = [{add: '/state', value: self.state}]
      attrs = Listings.fire_patch(Listings.listing_url(self.listing_id), patch)
      attrs ? self.class.new(attrs) : self
    end

    # Returns a hash from listing id to Stats objects for the identified listings.
    # @param ids listing ids to return stats for
    def self.stats(ids, options = {})
      options.merge!(ids: ids, params_map: {ids: :id}, default_data: {'stats' => {}})
      data = Listings.fire_get(Listings.stats_for_listings_url, options)
      data['stats'].each_with_object({}) {|(id, stats), h| h[id.to_i] = Stats.new(stats)}
    end

    def self.find(listing_id)
      attrs = Listings.fire_get(Listings.listing_url(listing_id))
      attrs ? new(attrs) : nil
    end

    def self.destroy(listing_id)
      Listings.fire_delete(Listings.listing_url(listing_id))
    end

    # Returns summary info about the comments for each identified listings
    #
    # @options option [Integer] user_id if provided, includes summary info relevant to that specific user
    # @return [Hash] listing summaries keyed by listing id
    def self.comment_summaries(ids, options)
      options = options.reverse_merge(default_data: {}, params_map: {user_id: :user_id})
      data = Listings.fire_get(Listings.listings_comment_summaries_url(ids), options)
      data.each_with_object({}) { |(id, attrs), m| m[id.to_i] = CommentSummary.new(attrs) }
    end

    class Stats < Ladon::Model
      attr_accessor :views, :shares, :listing_id
    end

    class CommentSummary < Ladon::Model
      attr_accessor :user_id, :commented, :total, :comments, :commenter_ids

      def initialize(attrs = {})
        super(attrs.except('comments'))
        @comments = attrs['comments'] ?
          attrs['comments'].each_with_object({}) do |(id, cattrs), m|
             m[id.to_s] = Anchor::Comment.new(cattrs.merge(id: id))
          end : {}
        end

      def commented_on_by_user?
        !!commented
      end

      def commenter_ids
        @commenter_ids ||= comments.values.map(&:user_id).uniq
      end
    end
  end
end
