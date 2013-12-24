require 'mongoid'

class CommentFlag
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: Integer
  index :user_id
  validates_presence_of :user_id
  validates_uniqueness_of :user_id

  field :reason, type: String
  validates_presence_of :reason
  validates_length_of :reason, maximum: 20, allow_blank: true

  field :description, type: String
  validates_length_of :description, maximum: 500, allow_blank: true

  embedded_in :comment
end
