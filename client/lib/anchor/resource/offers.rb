require 'anchor/resource/base'

module Anchor
  # The resource representing a listing.
  class Offers < Resource::Base
    def self.offers_url
      absolute_url("/offers")
    end

    def self.offer_url(offer_id)
      absolute_url("/offers/#{offer_id}")
    end
  end
end
