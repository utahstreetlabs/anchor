require 'ladon/model'
require 'anchor/resource/offers'

module Anchor
  class Offer < Ladon::Model
    attr_accessor :amount, :duration, :available, :user_types, :seller_ids
    validates :amount, presence: true, numericality: {greater_than: 0}
    validates :duration, presence: true
    validates :user_types, presence: true

    USER_TYPES = { new_users: 'NewUser', existing_users: 'ExistingUser' }
    USER_TYPES.each do |method,token|
      define_method(method) { user_types.include?(token) }
    end

    def initialize(attrs = {})
      attrs[:user_types] ||= USER_TYPES.keys.map { |k| attrs.delete(k) ? USER_TYPES[k] : nil }.compact
      super
    end

    def available
      @available || 0
    end

    def seller_ids
      (@seller_ids || []).map { |i| i.to_i }
    end

    def seller_specific?
      seller_ids.any?
    end

    def wire_hash
      serializable_hash(except: [:new_users, :existing_users])
    end

    def self.create(attrs)
      offer = new(attrs)
      if offer.valid?
        saved = Offers.fire_post(Offers.offers_url, offer.wire_hash)
        saved ? new(saved) : nil
      else
        offer
      end
    end

    def self.update(offer_id, attrs)
      offer = new(attrs)
      if offer.valid?
        saved = Offers.fire_put(Offers.offer_url(offer_id), offer.wire_hash)
        saved ? offer : nil
      else
        offer
      end
    end

    def self.all
      Offers.fire_get(Offers.offers_url, default_data: []).map { |o| new(o) }
    end

    def self.find(offer_id)
      attrs = Offers.fire_get(Offers.offer_url(offer_id))
      attrs ? new(attrs) : nil
    end
  end
end
