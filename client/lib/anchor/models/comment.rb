require 'ladon/model'
require 'anchor/models/comment_base'
require 'anchor/models/comment_reply'
require 'anchor/resource/comments'
require 'anchor/resource/listings'

module Anchor
  class Comment < CommentBase
    attr_accessor :listing_id, :replies
    validates :listing_id, presence: true, numericality: {only_integer: true, allow_blank: true}

    def initialize(attrs = {})
      super(attrs.except('child_comments'))
      @replies = attrs['child_comments'] ?
        (attrs['child_comments'].map {|rattrs| CommentReply.new(rattrs.merge(parent_id: self.id)) }) :
          []
    end

    def destroy
      Comments.fire_delete(Comments.comment_url(self.id))
    end

    def create_reply(attrs)
      reply = CommentReply.create(attrs.merge(parent_id: self.id))
      @replies << reply
      reply
    end

    def delete_reply(reply_or_id)
      if reply_or_id.is_a?(CommentReply)
        reply_or_id.destroy
        @replies.delete(reply_or_id)
      else
        CommentReply.destroy(self.id, reply_or_id)
        @replies.delete_if {|reply| reply.id == reply_or_id}
      end
    end

    # Creates and returns a +Comment+ based on the provided attributes hash. Returns nil if the service request fails.
    def self.create(attrs)
      comment = new(attrs)
      if comment.valid?
        entity = comment.serializable_hash(except: [:id, :created_at, :updated_at, :listing_id, :flags, :replies])
        saved = Listings.fire_post(Listings.listing_comments_url(comment.listing_id), entity)
        saved ? new(saved.merge(listing_id: comment.listing_id)) : nil
      else
        comment
      end
    end

    def self.find(listing_id, id)
      attrs = Comments.fire_get(Comments.comment_url(id))
      attrs ? new(attrs.merge(listing_id: listing_id)) : nil
    end

    def self.destroy(listing_id, id)
      Comments.fire_delete(Comments.comment_url(id))
    end
  end
end
