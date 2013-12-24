require 'dino/base'
require 'dino/mongoid'
require 'anchor/apps/comments'
require 'anchor/models/listing'

module Anchor
  class CommentRepliesApp < Dino::Base
    include Dino::MongoidApp

    post '/comments/:comment_id/replies' do
      do_post do |entity|
        raise Dino::BadRequest.new("Entity required") unless entity
        comment = Anchor::CommentsApp.find_comment!(params[:comment_id])
        logger.debug("Creating reply to comment %s with attributes %s" % [params[:comment_id], entity.inspect])
        comment.replies.create!(entity)
      end
    end

    delete '/comments/:comment_id/replies' do
      do_delete do
        comment = Anchor::CommentsApp.find_comment!(params[:comment_id])
        logger.debug("Deleting all replies for comment #{comment.id}")
        comment.replies.delete_all
      end
    end

    get '/comments/:comment_id/replies/:id' do
      do_get do
        comment = Anchor::CommentsApp.find_comment!(params[:comment_id])
        logger.debug("Finding reply #{params[:id]} to comment #{params[:comment_id]}")
        comment.replies.where(_id: params[:id]).first
      end
    end

    delete '/comments/:comment_id/replies/:id' do
      do_delete do
        comment = Anchor::CommentsApp.find_comment!(params[:comment_id])
        logger.debug("Deleting reply #{params[:id]} to comment #{comment.id} from user #{params[:user_id]}")
        comment.replies.delete_all(conditions: {id: params[:id]})
      end
    end
  end
end
