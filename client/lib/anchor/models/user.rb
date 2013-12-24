require 'ladon/model'
require 'anchor/resource/users'

module Anchor
  class User < Ladon::Model
    def self.destroy(user_id)
      Users.fire_delete(Users.user_url(user_id))
    end

    def self.destroy!(user_id)
      Users.fire_delete(Users.user_url(user_id), raise_on_error: true)
    end
  end
end
