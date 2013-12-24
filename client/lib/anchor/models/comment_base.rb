require 'ladon/model'
require 'anchor/models/comment_base'
require 'anchor/models/comment_flag'

module Anchor
  class CommentBase < Ladon::Model
    attr_accessor :user_id, :text, :flags
    validates :user_id, presence: true, numericality: {only_integer: true, allow_blank: true}
    validates :text, presence: true, length: {maximum: 500, allow_blank: true}

    def initialize(attrs = {})
      super(attrs.reject {|key, value| key == 'flags'})
      @flags = attrs['flags'] ? (attrs['flags'].map {|fattrs| Anchor::CommentFlag.new(fattrs) }) : []
    end

    def type
      :comment
    end

    def create_flag(attrs)
      flag = CommentFlag.create(self.id, attrs)
      @flags << flag
      flag
    end

    def unflag
      CommentFlag.delete_all(self.id)
      @flags.clear
    end

    def flagged?
      flags.any?
    end

    def flagged_by?(user_id)
      !flag_by(user_id).nil?
    end

    def flag_by(user_id)
      flags.detect {|flag| flag.user_id == user_id}
    end

    def grouped_flags
      flags.group_by {|flag| flag.reason}
    end
  end
end
