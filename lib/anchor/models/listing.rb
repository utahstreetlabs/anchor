require 'mongoid'
require 'mongoid/patchable'
require 'anchor/models/comment'
require 'anchor/models/paginatable'
require 'kaminari/models/configuration_methods'
require 'kaminari/models/array_extension'

class Listing
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Patchable
  include Paginatable

  field :listing_id, type: Integer
  index :listing_id
  validates_presence_of :listing_id
  validates_uniqueness_of :listing_id, :allow_nil => true

  field :views, type: Integer, default: 0

  # shares can't be modeled as an embedded document because we don't want to have to hardcode fields for each
  # network. this means we can't use atomic incrementing.
  field :shares, type: Hash, default: {}

  field :state, type: String

  embeds_many :comments, validate: false

  alias_method :model_id, :listing_id

  # Returns the most recent comments for this listing, up to the specified limit (default +3+).
  def recent_comments(limit = 3)
    comments.order_by([:created_at, :desc]).limit(limit)
  end

  # Returns a hash summary info for this listing, including view and share counts and listing id.
  #
  # @options Array<Symbol> includes When specified, limits the returned hash to only the keys specified in this array
  def stats(options = {})
    # why does options.fetch(:includes, []) return nil when it's not provided?
    includes = (options[:includes] || []).map(&:to_sym)
    rv = {}
    rv[:views] = views if includes.empty? or includes.include?(:views)
    rv[:shares] = shares if includes.empty? or includes.include?(:shares)
    rv
  end

  # Transforms a listing into a hash that suitably represents the listing on the wire. It excludes all associated
  # documents that are hidden or have their own endpoints and converts the BSON id into its string form.
  def to_wire_hash
    hash = serializable_hash(except: [:comments])
    hash['_id'] = hash['_id'].to_s
    hash
  end

  def total_comments_and_replies
    comments.inject(comments.count) { |m, c| m + c.replies.count }
  end

  def comment_summaries
    comments.each_with_object({}) do |comment, m|
      m[comment.id] = {listing_id: comment.listing.id.to_s,
        user_id: comment.user_id, text: comment.text, created_at: comment.created_at.to_time.to_i}
      replies = comment.replies.each_with_object({}) do |reply, rm|
        rm[reply.id] = {listing_id: comment.listing.id.to_s,
          user_id: reply.user_id, text: reply.text, created_at: reply.created_at.to_time.to_i}
      end
      m.merge!(replies)
    end
  end

  def commented_on_by_user?(user_id)
    comments.each do |comment|
      return true if comment.user_id == user_id
      comment.replies.each do |reply|
        return true if reply.user_id == user_id
      end
    end
    false
  end

  def delete_user_info(user_id)
    comments.where(user_id: user_id).delete_all
    comments.each do |comment|
      comment.replies.where(user_id: user_id).delete_all
      comment.flags.where(user_id: user_id).delete_all
      comment.replies.each do |reply|
        reply.flags.where(user_id: user_id).delete_all
      end
    end
  end

  # Returns summary info about the comments for each identified listings
  #
  # @options option [Integer] user_id if provided, includes summary info relevant to that specific user
  # @options option [Integer] limit number of comments to return (default is return all comments)
  # @return [Hash] listing summaries keyed by listing id
  def self.comment_summaries(ids, options = {})
    user_id = options[:user_id].to_i
    # this is bollocks. it loads all of the comments and replies for each listing across the network. it would surely
    # be much more efficient to do the aggregation on the mongo side, but I have no idea how to accomplish that. and
    # soon enough we're going to have to return the most recent n comments anyway, so this may ultimately be the best
    # solution anyway as long as the total number of comments and replies on a listing is not typically much larger
    # than n.
    comments = any_in(listing_id: ids).only(:listing_id, :comments)
    comments = comments.limit(options[:limit]) if options[:limit]
    comments.each_with_object({}) do |listing, m|
      summary = {total: listing.total_comments_and_replies, comments: listing.comment_summaries}
      if user_id > 0
        summary[:commented] = listing.commented_on_by_user?(user_id)
        summary[:user_id] = user_id
      end
      m[listing.listing_id] = summary
    end
  end

  USER_KEYS = ['user_id', 'child_comments.user_id', 'flags.user_id', 'child_comments.flags.user_id']
  def self.with_user_association(user_id)
    any_of(*USER_KEYS.map { |k| {"comments.#{k}" => user_id} })
  end
end
