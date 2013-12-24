require 'dino/base'
require 'dino/mongoid'
require 'anchor/models/listing'

module Anchor
  class CommentsApp < Dino::Base
    include Dino::MongoidApp

    get '/comments/:id' do
      do_get do
        logger.debug("Finding comment #{params[:id]}")
        self.class.find_comment!(params[:id])
      end
    end

    delete '/comments/:id' do
      do_delete do
        logger.debug("Deleting comment #{params[:id]}")
        comment = self.class.find_comment(params[:id])
        comment.destroy if comment
      end
    end

    def self.find_comment!(comment_id)
      find_comment(comment_id) or raise Dino::NotFound
    end

    def self.find_comment(comment_id)
      comment_id = BSON::ObjectId.from_string(comment_id)
      # use +to_a+ to realize the result before the call to +first+ because mongoid makes some bad decisions about
      # how to implement +first+ and keeps mongo from using indexes
      listing = Listing.any_of({'comments._id' => comment_id}, {'comments.child_comments._id' => comment_id}).to_a.
        first
      return nil unless listing
      comment = listing.comments.where(_id: comment_id).first
      return comment if comment
      # not super happy with this, because in the worst case it scans every child of every comment, but I can't find
      # a better way to formulate a query for both the comments and replies
      listing.comments.each do |c|
        comment = c.child_comments.where(_id: comment_id).first
        return comment if comment
      end
      return nil
    end
  end
end
