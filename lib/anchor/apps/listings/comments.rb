require 'dino/base'
require 'dino/mongoid'
require 'anchor/apps/listing_autocreatable'

module Anchor
  class ListingCommentsApp < Dino::Base
    include Dino::MongoidApp
    include Anchor::ListingAutocreatable

    get '/listings/:listing_id/comments' do
      do_get do
        listing = find_or_create_listing(params[:listing_id])
        max = params.fetch('max', 25).to_i
        logger.debug("Getting #{max} comments for listing #{params[:listing_id]}")
        {comments: listing.recent_comments(max)}
      end
    end

    post '/listings/:listing_id/comments' do
      do_post do |entity|
        raise Dino::BadRequest.new("Entity required") unless entity
        listing = find_or_create_listing(params[:listing_id])
        logger.debug("Saving comment on listing #{params[:listing_id]} with attributes #{entity.inspect}")
        listing.comments.create!(entity)
      end
    end

    delete '/listings/:listing_id/comments' do
      do_delete do
        listing = Listing.where(listing_id: params[:listing_id]).first
        raise Dino::NotFound unless listing
        logger.debug("Deleting comments of listing #{params[:listing_id]}")
        listing.comments.destroy_all(user_id: params[:user_id])
      end
    end

    get '/listings/:listing_id/comments/count' do
      do_get do
        {count: find_or_create_listing(params[:listing_id]).comments.count}
      end
    end

    get '/listings/many/:listing_ids/comments/summaries' do
      do_get do
        ids = params[:listing_ids].split(';')
        options = {user_id: params[:user_id]}
        logger.debug("Getting comment summaries for listings #{ids} with options #{options}")
        Listing.comment_summaries(ids, options)
      end
    end
  end
end
