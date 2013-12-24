require 'mongoid'
require 'anchor/models/listing'
require 'anchor/models/comment_flag'

class Comment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: Integer
  index :user_id
  validates_presence_of :user_id

  field :text, type: String
  validates_presence_of :text
  validates_length_of :text, maximum: 500, allow_blank: true

  embedded_in :listing
  embeds_many :flags, class_name: 'CommentFlag', validate: false

  recursively_embeds_many # child_comments

  def replies
    child_comments
  end
end
