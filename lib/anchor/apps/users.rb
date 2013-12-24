require 'dino/base'
require 'dino/mongoid'
require 'anchor/models/listing'

module Anchor
  class UsersApp < Dino::Base
    include Dino::MongoidApp

    delete '/users/:id' do
      do_delete do
        user_id = params[:id].to_i
        Listing.with_user_association(user_id).each { |l| l.delete_user_info(user_id) }
      end
    end
  end
end
