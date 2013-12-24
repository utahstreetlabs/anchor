require 'anchor/resource/base'

module Anchor
  # The resource representing the flags on a listing's comment.
  class CommentFlags < Resource::Base
    def self.comment_flags_url(comment_id)
      absolute_url("/comments/#{comment_id}/flags")
    end

    def self.comment_flags_user_url(comment_id, user_id)
      absolute_url("/comments/#{comment_id}/flags/users/#{user_id}")
    end
  end
end
