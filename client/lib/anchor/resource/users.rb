require 'anchor/resource/base'

module Anchor
  class Users < Resource::Base
    def self.user_url(user_id)
      absolute_url("/users/#{user_id}")
    end
  end
end
