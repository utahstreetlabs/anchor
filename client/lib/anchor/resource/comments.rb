require 'anchor/resource/base'

module Anchor
  # The resource representing the comments on a listing
  class Comments < Resource::Base
    def self.comment_url(id)
      absolute_url("/comments/#{id}")
    end
  end
end
