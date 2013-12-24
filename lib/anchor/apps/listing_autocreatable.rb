require 'anchor/models/listing'

module Anchor
  module ListingAutocreatable
    def find_or_create_listing(listing_id)
      # optimization - if somebody asks for a listing and it doesn't exist, autocreate it. we can change that behavior
      # when/if Anchor becomes the primary repository for listing data, but for now, if somebody asks for a listing,
      # assume that it is meant to exist.
      Listing.find_or_create_by(listing_id: listing_id)
    end

    def find_or_create_listings(listing_ids)
      if listing_ids.any?
        listing_ids = listing_ids.map(&:to_i)
        existing = Listing.any_in(listing_id: listing_ids).inject({}) {|m, l| m.merge(l.listing_id => l)}
        listing_ids.map {|id| existing.include?(id) ? existing[id] : Listing.create!(listing_id: id)}
      else
        []
      end
    end
  end
end
