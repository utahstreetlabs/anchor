require 'dino/base'
require 'dino/mongoid'
require 'anchor/apps/listing_autocreatable'
require 'anchor/models/listing'
require 'json/patch'

module Anchor
  class ListingsApp < Dino::Base
    include Dino::MongoidApp
    include Anchor::ListingAutocreatable

    get '/listings/stats' do
      do_get do
        ids = params.fetch('id', [])
        stats = if ids.any?
          logger.debug("Getting stats for listings #{params[:id]}")
          opts = {user_id: params[:user_id], includes: params[:fields]}
          find_or_create_listings(ids).each_with_object({}) do |l, h|
            h[l.listing_id] = l.stats(opts)
          end
        else
          []
        end
        {stats: stats}
      end
    end

    get '/listings/:id' do
      do_get do
        logger.debug("Finding listing #{params[:id]}")
        find_listing!(params[:id]).to_wire_hash
      end
    end

    patch '/listings/:id' do
      do_patch do |patch|
        raise Dino::BadRequest unless patch
        begin
          listing = find_or_create_listing(params[:id])
          logger.debug("Updating listing #{params[:id]} with patch #{patch}")
          if JSON::Patch.new(patch).apply_to(listing)
            find_listing!(params[:id])
          else
            raise Dino::UnprocessableEntity
          end
        rescue ArgumentError
          raise Dino::BadRequest
        end
      end
    end

    delete '/listings/:id' do
      do_delete do
        logger.debug("Deleting listing #{params[:id]}")
        listing = find_listing(params[:id])
        listing.destroy if listing
      end
    end

    post '/listings/:id/views' do
      do_post do
        listing = find_listing!(params[:id])
        logger.debug("Incrementing views for listing #{params[:id]}")
        listing.inc(:views, 1)
        listing.to_wire_hash
      end
    end

    post '/listings/:id/shares/:network' do
      do_post do
        listing = find_listing!(params[:id])
        logger.debug("Incrementing #{params[:network]} shares for listing #{params[:id]}")
        # because we have to model share_counts as a hash and don't know if a particular network has been added to the
        # hash before, we can't use mongo's atomic increment feature, which means we have a race condition and may
        # lose some updates.
        if listing.shares.include?(params[:network])
          listing.shares[params[:network]] += 1
        else
          listing.shares[params[:network]] = 1
        end
        listing.save!
        listing.to_wire_hash
      end
    end

    def find_listing(listing_id)
      Listing.where(listing_id: listing_id).first
    end

    def find_listing!(listing_id)
      find_listing(listing_id) or raise Dino::NotFound
    end
  end
end
