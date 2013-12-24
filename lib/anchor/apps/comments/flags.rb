require 'dino/base'
require 'dino/mongoid'
require 'anchor/apps/comments'
require 'anchor/models/listing'

module Anchor
  class CommentFlagsApp < Dino::Base
    include Dino::MongoidApp

    get '/comments/:comment_id/flags' do
      do_get do
        comment = Anchor::CommentsApp.find_comment!(params[:comment_id])
        logger.debug("Getting all flags for comment #{comment.id}")
        {flags: comment.flags}
      end
    end

    get '/comments/:comment_id/flags/users/:user_id' do
      do_get do
        comment = Anchor::CommentsApp.find_comment!(params[:comment_id])
        logger.debug("Getting flag for comment #{comment.id} from user #{params[:user_id]}")
        flag = comment.flags.where(user_id: params[:user_id]).first
        raise Dino::NotFound.new("No such flag") unless flag
        flag
      end
    end

    put '/comments/:comment_id/flags/users/:user_id' do
      do_put do |entity|
        raise Dino::BadRequest.new("Entity required") unless entity
        comment = Anchor::CommentsApp.find_comment!(params[:comment_id])
        flag = comment.flags.where(user_id: params[:user_id]).first
        # the user can't keep repeatedly flagging the listing
        if flag
          logger.warn("Not flagging comment #{comment.id} for user #{params[:user_id]}: already flagged")
        else
          logger.debug("Saving flag for comment #{comment.id} from user #{params[:user_id]}")
          flag = comment.flags.create!(entity.merge(user_id: params[:user_id]))
        end
        flag
      end
    end

    delete '/comments/:comment_id/flags' do
      do_delete do
        comment = Anchor::CommentsApp.find_comment!(params[:comment_id])
        logger.debug("Deleting all flags for comment #{comment.id}")
        comment.flags.delete_all
      end
    end

    delete '/comments/:comment_id/flags/users/:user_id' do
      do_delete do
        comment = Anchor::CommentsApp.find_comment!(params[:comment_id])
        logger.debug("Deleting flag for comment #{comment.id} from user #{params[:user_id]}")
        comment.flags.delete_all(conditions: {user_id: params[:user_id]})
      end
    end
  end
end
