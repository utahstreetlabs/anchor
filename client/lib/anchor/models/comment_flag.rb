require 'ladon/model'
require 'anchor/resource/comment_flags'

module Anchor
  class CommentFlag < Ladon::Model
    attr_accessor :user_id, :reason, :description
    validates :user_id, presence: true, numericality: {only_integer: true, allow_blank: true}
    validates :reason, presence: true, length: {maximum: 20, allow_blank: true}
    validates :description, length: {maximum: 500, allow_blank: true}

    # Creates and returns a +CommentFlag+ based on the provided attributes hash. Returns nil if the service request
    # fails.
    def self.create(comment_id, attrs)
      flag = new(attrs)
      if flag.valid?
        entity = flag.serializable_hash(except: [:id, :created_at, :updated_at, :user_id])
        saved = CommentFlags.fire_put(CommentFlags.comment_flags_user_url(comment_id, flag.user_id), entity)
        rv = saved ? new(saved) : nil
      else
        flag
      end
    end

    def self.delete_all(comment_id)
      CommentFlags.fire_delete(CommentFlags.comment_flags_url(comment_id))
    end
  end
end
