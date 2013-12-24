require 'spec_helper'
require 'rack/test'
require 'anchor/apps/users'

describe Anchor::UsersApp do
  include Rack::Test::Methods

  def app
    Anchor::UsersApp
  end

  describe 'DELETE /users/:id' do
    let(:user_id) { 456 }

    it 'deletes user comments' do
      listing = Factory.create(:listing)
      comment = Factory.create(:comment, listing: listing, user_id: user_id, text: '(boom)')
      delete "/users/#{user_id}"
      last_response.status.should == 204
      expect(listing.reload.comments).to have(:no).comments
    end
  end
end
