require 'ladon/model'
require 'anchor/models/comment_base'
require 'anchor/resource/comment_replies'

module Anchor
  class CommentReply < CommentBase
    attr_accessor :parent_id
    validates :parent_id, presence: true

    def destroy
      CommentReplies.fire_delete(CommentReplies.comment_reply_url(self.parent_id, self.id))
    end

    # Creates and returns a +Reply+ based on the provided attributes hash. Returns nil if the service request fails.
    def self.create(attrs)
      reply = new(attrs)
      if reply.valid?
        entity = reply.serializable_hash(except: [:id, :created_at, :updated_at, :parent_id, :flags, :replies])
        saved = CommentReplies.fire_post(CommentReplies.comment_replies_url(reply.parent_id), entity)
        saved ? new(saved.merge(parent_id: reply.parent_id)) : nil
      else
        reply
      end
    end

    def self.destroy(parent_id, id)
      CommentReplies.fire_delete(CommentReplies.comment_reply_url(parent_id, id))
    end
  end
end
