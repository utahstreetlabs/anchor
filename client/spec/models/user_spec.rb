require 'spec_helper'
require 'anchor/models/user'

describe Anchor::User do
  describe '::destroy' do
    let(:user_id) { 123 }
    it 'deletes a user' do
      Anchor::Users.expects(:fire_delete).with(Anchor::Users.user_url(user_id))
      Anchor::User.destroy(user_id)
    end
  end
end
