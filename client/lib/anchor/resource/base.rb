require 'ladon/resource/base'

module Anchor
  module Resource
    # Just here so that we can set class attributes for all Anchor resources.
    class Base < Ladon::Resource::Base
      self.base_url = 'http://localhost:4010'

      # Force all subclasses to use the base class's base url.
      def self.base_url
        self == Base ? super : Base.base_url
      end

      def self.grouped_query_path_segment(ids)
        ids.sort.join(';')
      end
    end
  end
end
