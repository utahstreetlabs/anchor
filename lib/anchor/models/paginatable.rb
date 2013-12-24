module Paginatable
  extend ActiveSupport::Concern

  module ClassMethods
    # Returns an array of objects as a paged array.
    #
    # @param [Array] original
    # @param [Hash] options
    # @option options [Integer] :offset (0)
    # @option options [Integer] :limit (all)
    # @option options [Boolean] :disallow_all interprets a limit of nil or 0 literally, returning an empty array
    def paged_array(original, options = {})
      limit = options[:limit].to_i
      unless options[:disallow_all]
        # the client is asking for all results, so we need to set the limit to an arbitrarily high number to get around
        # the built-in default limit
        limit = 10000000 if limit == 0
      end
      offset = options[:offset].to_i
      Kaminari::PaginatableArray.new(original, limit: limit, offset: offset)
    end
  end
end
