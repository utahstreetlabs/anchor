require 'anchor/resource/base'

module Anchor
  # The resource representing a listing.
  class Listings < Resource::Base
    def self.listing_url(listing_id)
      absolute_url("/listings/#{listing_id}")
    end

    def self.listing_views_url(listing_id)
      absolute_url("/listings/#{listing_id}/views")
    end

    def self.listing_shares_url(listing_id, network)
      absolute_url("/listings/#{listing_id}/shares/#{network}")
    end

    def self.listing_comments_url(listing_id, options = {})
      params = {}
      params[:max] = options[:max].to_s if options[:max]
      absolute_url("/listings/#{listing_id}/comments", params: params)
    end

    def self.listing_comments_count_url(listing_id)
      absolute_url("/listings/#{listing_id}/comments/count")
    end

    def self.stats_for_listings_url
      absolute_url('/listings/stats')
    end

    def self.listings_comment_summaries_url(ids)
      absolute_url("/listings/many/#{grouped_query_path_segment(ids)}/comments/summaries")
    end
  end
end
