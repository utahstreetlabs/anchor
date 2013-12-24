require 'anchor/resource/base'

module Anchor
  # The resource representing the replies to a listing's comment.
  class CommentReplies < Resource::Base
    def self.comment_replies_url(comment_id)
      absolute_url("/comments/#{comment_id}/replies")
    end

    def self.comment_reply_url(comment_id, id)
      absolute_url("/comments/#{comment_id}/replies/#{id}")
    end
  end
end
